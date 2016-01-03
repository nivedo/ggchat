//
//  WikiMediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 12/29/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import Kingfisher

class WikiMediaItem: MediaItem {
    
    var cachedView_: UIView?
    var cachedImageView_: UIImageView?
    var imageURL: NSURL!
    // var image_: UIImage?
    let inset: CGFloat = CGFloat(6.0)

    // pragma mark - Initialization

    init(imageURL: NSURL, delegate: MessageMediaDelegate?) {
        super.init()
        // self.image_ = image.copy() as? UIImage
        self.delegate = delegate
        self.imageURL = imageURL
        self.cachedView_ = UIView(frame: CGRectMake(0.0, 0.0, 210.0, 150.0))
        self.cachedImageView_ = UIImageView(frame: CGRectMake(0.0, 0.0, 210.0, 150.0))
        
        let hud = MBProgressHUD.showHUDAddedTo(self.cachedView_, animated: true)
        hud.mode = MBProgressHUDMode.AnnularDeterminate
        hud.labelText = "Downloading"
        
        self.cachedImageView_!.kf_setImageWithURL(imageURL,
            placeholderImage: nil,
            // optionsInfo: [.Transition(ImageTransition.Fade(1))],
            optionsInfo: nil,
            progressBlock: { (receivedSize, totalSize) -> () in
                hud.progress = Float(receivedSize) / Float(totalSize)
            },
            completionHandler: { (image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> () in
                // print("Downloaded")
                if let img = image {
                    let size: CGSize = self.imageDisplaySize(img)
                    if let view = self.cachedView_, let imageView = self.cachedImageView_ {
                        view.frame = CGRectMake(0.0, 0.0, size.width, size.height)
                        view.bounds = CGRectInset(view.frame, -self.inset, -self.inset)
                        imageView.frame = CGRectMake(0.0, 0.0, size.width - 2*self.inset, size.height - 2*self.inset)
                        imageView.contentMode = UIViewContentMode.ScaleAspectFill
                        imageView.clipsToBounds = true
                        imageView.layer.masksToBounds = true
                        imageView.layer.cornerRadius = 8.0
                        view.addSubview(imageView)
                        // self.cachedView_ = view
                        self.setNeedsDisplay()
                        self.delegate?.redrawMessageMedia()
                    }
                }
                hud.hide(true)
        })
    }

    deinit {
        self.cachedImageView_ = nil
        self.cachedView_ = nil
    }
    
    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedImageView_ = nil
        self.cachedView_ = nil
    }

    // pragma mark - Setters

    var image: UIImage? {
        /*
        set {
            if newValue != nil {
                self.image_ = newValue!.copy() as? UIImage
            } else {
                self.image_ = nil
            }
            self.cachedView_ = nil
        }
        */
        set {
            if newValue != nil {
                self.cachedImageView_?.image = newValue!.copy() as? UIImage
            } else {
                self.clearCachedMediaViews()
            }
        }
        get {
            return self.cachedImageView_?.image
        }
    }

    /*
    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            if oldValue != self.appliesMediaViewMaskAsOutgoing {
                self.clearCachedMediaViews()
            }
        }
    }
    */

    // pragma mark - MessageMediaData protocol
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        self.cachedView_?.setNeedsDisplay()
    }
   
    func imageDisplaySize(image: UIImage) -> CGSize {
        let size = CGSizeMake(210.0, UIScreen.mainScreen().bounds.size.height)
        let aspect: CGFloat = image.size.width / image.size.height
        if size.width / aspect <= size.height {
            return CGSizeMake(size.width, size.width / aspect)
        } else {
            return CGSizeMake(size.height * aspect, size.height)
        }
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        if let img = self.image {
            return self.imageDisplaySize(img)
        } else {
            if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                return CGSizeMake(315.0, 225.0)
            } else {
                return CGSizeMake(210.0, 150.0)
            }
        }
        /*
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
        */
    }
    
    override func mediaView() -> UIView? {
        /*
        if (self.image == nil) {
            return nil
        }
        
        if (self.cachedView_ == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let view: UIView = UIView(frame: CGRectMake(0.0, 0.0, size.width, size.height))
            view.bounds = CGRectInset(view.frame, -self.inset, -self.inset)
            if let imageView = self.cachedImageView_ {
                imageView.frame = CGRectMake(0.0, 0.0, size.width - 2*self.inset, size.height - 2*self.inset)
                imageView.contentMode = UIViewContentMode.ScaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.masksToBounds = true
                imageView.layer.cornerRadius = 8.0
                view.addSubview(imageView)
                self.cachedView_ = view
            }
        }
        */
        
        return self.cachedView_
    }

    override func mediaHash() -> Int {
        return self.hash
    }

    // pragma mark - NSObject

    override var hash: Int {
        if self.image != nil {
            return super.hash ^ self.image!.hash
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
        self.image = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("image"))) as? UIImage
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
        let copy: WikiMediaItem = WikiMediaItem(imageURL: self.imageURL, delegate: self.delegate)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}