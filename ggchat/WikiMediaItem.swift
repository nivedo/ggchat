//
//  WikiMediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 12/29/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class WikiMediaItem: MediaItem {
    
    var cachedView_: UIView?
    var image_: UIImage?
    let inset: CGFloat = CGFloat(6.0)

    // pragma mark - Initialization

    init(image: UIImage) {
        super.init()
        self.image_ = image.copy() as? UIImage
        self.cachedView_ = nil
    }

    deinit {
        self.image = nil
        self.cachedView_ = nil
    }
    
    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedView_ = nil
    }

    // pragma mark - Setters

    var image: UIImage? {
        set {
            if newValue != nil {
                self.image_ = newValue!.copy() as? UIImage
            } else {
                self.image_ = nil
            }
            self.cachedView_ = nil
        }
        get {
            return self.image_
        }
    }

    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            if oldValue != self.appliesMediaViewMaskAsOutgoing {
                self.cachedView_ = nil
            }
        }
    }

    // pragma mark - MessageMediaData protocol
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        self.cachedView_?.setNeedsDisplay()
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        if let img = self.image_ {
            let size = CGSizeMake(210.0, UIScreen.mainScreen().bounds.size.height)
            let aspect: CGFloat = img.size.width / img.size.height
            if size.width / aspect <= size.height {
                return CGSizeMake(size.width, size.width / aspect)
            } else {
                return CGSizeMake(size.height * aspect, size.height)
            }
        } else {
            if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                return CGSizeMake(315.0, 225.0)
            } else {
                return CGSizeMake(210.0, 150.0)
            }
        }
    }
    
    override func mediaView() -> UIView? {
        if (self.image_ == nil) {
            return nil
        }
        
        if (self.cachedView_ == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let view: UIView = UIView(frame: CGRectMake(0.0, 0.0, size.width, size.height))
            view.bounds = CGRectInset(view.frame, -self.inset, -self.inset)
            let imageView: UIImageView = UIImageView(image: self.image_)
            imageView.frame = CGRectMake(0.0, 0.0, size.width - 2*self.inset, size.height - 2*self.inset)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 8.0
            view.addSubview(imageView)
            self.cachedView_ = view
        }
        
        return self.cachedView_
    }

    override func mediaHash() -> Int {
        return self.hash
    }

    // pragma mark - NSObject

    override var hash: Int {
        if self.image_ != nil {
            return super.hash ^ self.image_!.hash
        } else {
            return super.hash
        }
    }

    override var description: String {
        return "<\(self.dynamicType): image=\(self.image), appliesMediaViewMaskAsOutgoing=\(self.appliesMediaViewMaskAsOutgoing)>"
    }
    
    // pragma mark - NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.image_ = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("image"))) as? UIImage
    }

    required init() {
        super.init()
    }

    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.image_,
            forKey: NSStringFromSelector(Selector("image")))
    }

    // pragma mark - NSCopying

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: WikiMediaItem = WikiMediaItem(image: self.image_!)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}