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
    var placeholderURL: String?
    var placeholderImage: UIImage?
    let inset: CGFloat = CGFloat(6.0)
    var downloaded: Bool = false

    // pragma mark - Initialization

    init(imageURL: NSURL, placeholderURL: String?, delegate: MessageMediaDelegate?) {
        super.init()
        // self.placeholderImage = UIImage(named: "mtg_back")
        self.placeholderImage = GGWikiCache.sharedInstance.retreiveImage(placeholderURL)
        // assert(self.placeholderImage != nil, "placeholder image is nil")
        self.delegate = delegate
        self.imageURL = imageURL
       
        self.initView()
        self.initImageView()
       
        /*
        let resource = Resource(downloadURL: imageURL)
        KingfisherManager.sharedManager.retrieveImageWithResource(resource,
            optionsInfo: nil,
            progressBlock: nil,
            completionHandler: nil)
        */
    }
 
    func initImageView() {
        self.cachedImageView_!.kf_setImageWithURL(imageURL,
            placeholderImage: self.placeholderImage,
            optionsInfo: nil,
            progressBlock: nil,
            completionHandler: { (image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> () in
                if let img = image {
                    let size: CGSize = self.imageDisplaySize(img)
                    self.setupFramesWithSize(size)
                    self.downloaded = true
                }
        })
    }

    func setupFramesWithSize(size: CGSize) {
        if let view = self.cachedView_, let imageView = self.cachedImageView_ {
            view.frame = CGRectMake(0.0, 0.0, size.width, size.height)
            view.bounds = CGRectInset(view.frame, -self.inset, -self.inset)
            imageView.frame = CGRectMake(0.0, 0.0, size.width - 2*self.inset, size.height - 2*self.inset)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 8.0
            // view.addSubview(imageView)
            // self.setNeedsDisplay()
        }
    }
   
    func initView() {
        if self.cachedView_ == nil {
            if let placeholderImage = self.placeholderImage {
                let size = self.imageDisplaySize(placeholderImage)
                self.cachedView_ = UIView()
                self.cachedImageView_ = UIImageView(image: placeholderImage)
                self.cachedView_?.addSubview(self.cachedImageView_!)
                self.setupFramesWithSize(size)
            } else {
                let size = self.defaultDisplaySize()
                self.cachedView_ = UIView(frame: CGRectMake(0.0, 0.0, size.width, size.height))
                self.cachedImageView_ = UIImageView(frame: CGRectMake(0.0, 0.0, size.width, size.height))
                self.cachedView_?.addSubview(self.cachedImageView_!)
            }
        }
    }
    
    func initImageViewWithHUD() {
        if !self.downloaded {
            self.downloaded = true
            if !KingfisherManager.sharedManager.cache.isImageCachedForKey(self.imageURL.absoluteString).cached {
                let hud = MBProgressHUD.showHUDAddedTo(self.cachedView_, animated: true)
                hud.mode = MBProgressHUDMode.AnnularDeterminate
                hud.labelText = "Downloading"
                
                // self.cachedImageView_!.kf_showIndicatorWhenLoading = true
                self.cachedImageView_!.kf_setImageWithURL(imageURL,
                    placeholderImage: self.placeholderImage,
                    optionsInfo: nil,
                    progressBlock: { (receivedSize, totalSize) -> () in
                        hud.progress = Float(receivedSize) / Float(totalSize)
                    },
                    completionHandler: { (image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> () in
                        if let img = image {
                            let size: CGSize = self.imageDisplaySize(img)
                            self.setupFramesWithSize(size)
                        }
                        hud.hide(true)
                        self.delegate?.redrawMessageMedia()
                })
            } else {
                self.cachedImageView_!.kf_setImageWithURL(imageURL,
                    placeholderImage: self.placeholderImage,
                    optionsInfo: nil,
                    progressBlock: nil,
                    completionHandler: { (image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> () in
                        if let img = image {
                            let size: CGSize = self.imageDisplaySize(img)
                            self.setupFramesWithSize(size)
                        }
                        self.delegate?.redrawMessageMedia()
                })
            }
        }
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

    // pragma mark - MessageMediaData protocol
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        self.cachedView_?.setNeedsDisplay()
        self.cachedImageView_?.setNeedsDisplay()
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
        } else if let placeholder = self.placeholderImage {
            return self.imageDisplaySize(placeholder)
        } else {
            return self.defaultDisplaySize()
        }
    }
    
    func defaultDisplaySize() -> CGSize {
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return CGSizeMake(315.0, 436.0)
        } else {
            return CGSizeMake(210.0, 290.0)
        }
    }

    
    
    override func mediaView() -> UIView? {
        // self.initView()
        self.initImageViewWithHUD()
    
        return self.cachedView_
    }
    
    override func mediaPlaceholderView() -> UIView? {
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
        let copy: WikiMediaItem = WikiMediaItem(imageURL: self.imageURL, placeholderURL: self.placeholderURL, delegate: self.delegate)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}