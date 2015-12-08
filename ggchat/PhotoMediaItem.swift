//
//  PhotoMediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class PhotoMediaItem: MediaItem {
    
    var cachedImageView_: UIImageView?
    var image_: UIImage?

    // pragma mark - Initialization

    init(image: UIImage) {
        super.init()
        self.image_ = image.copy() as? UIImage
        self.cachedImageView_ = nil
    }

    deinit {
        self.image = nil
        self.cachedImageView_ = nil
    }
    
    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedImageView_ = nil
    }

    // pragma mark - Setters

    var image: UIImage? {
        set {
            if newValue != nil {
                self.image_ = newValue!.copy() as! UIImage
            } else {
                self.image_ = nil
            }
            self.cachedImageView_ = nil
        }
        get {
            return self.image_
        }
    }

    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            self.cachedImageView_ = nil
        }
    }

    // pragma mark - MessageMediaData protocol

    override func mediaView() -> UIView? {
        if (self.image == nil) {
            return nil
        }
        
        if (self.cachedImageView_ == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let imageView: UIImageView = UIImageView(image: self.image)
            imageView.frame = CGRectMake(0.0, 0.0, size.width, size.height)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            MessageMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(
                imageView,
                isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedImageView_ = imageView
        }
        
        return self.cachedImageView_
    }

    override func mediaHash() -> Int {
        return self.hash
    }

    // pragma mark - NSObject

    override var hash: Int {
        return super.hash ^ self.image!.hash
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
        aCoder.encodeObject(self.image,
            forKey: NSStringFromSelector(Selector("image")))
    }

    // pragma mark - NSCopying

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: PhotoMediaItem = PhotoMediaItem(image: self.image!)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}
