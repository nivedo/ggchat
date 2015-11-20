//
//  VideoMediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class VideoMediaItem: MediaItem {
    
    var cachedVideoImageView: UIImageView?

    // pragma mark - Initialization

    init(fileURL: NSURL, isReadyToPlay: Bool) {
        super.init()
        self.fileURL = fileURL.copy() as! NSURL
        self.isReadyToPlay = isReadyToPlay
        self.cachedVideoImageView = nil
    }

    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedVideoImageView = nil
    }

    // pragma mark - Setters

    var fileURL: NSURL? {
        didSet {
            self.cachedVideoImageView = nil
        }
    }

    var isReadyToPlay: Bool = false {
        didSet {
            self.cachedVideoImageView = nil
        }
    }

    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            self.cachedVideoImageView = nil
        }
    }

    // pragma mark - MessageMediaData protocol

    override func mediaView() -> UIView? {
        if (!self.isReadyToPlay) {
            return nil
        }
        
        if (self.cachedVideoImageView == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let playIcon: UIImage = UIImage.gg_defaultPlayImage().gg_imageMaskedWithColor(UIColor.lightGrayColor())
            
            let imageView: UIImageView = UIImageView(image: playIcon)
            imageView.backgroundColor = UIColor.blackColor()
            imageView.frame = CGRectMake(0.0, 0.0, size.width, size.height)
            imageView.contentMode = UIViewContentMode.Center
            imageView.clipsToBounds = false
            MessageMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(
                imageView,
                isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedVideoImageView = imageView
        }
        
        return self.cachedVideoImageView
    }

    // pragma mark - NSObject

    override func isEqual(_ object: AnyObject?) -> Bool {
        if (!super.isEqual(object)) {
            return false
        }
        
        let videoItem: VideoMediaItem = object as! VideoMediaItem
        
        return self.fileURL == videoItem.fileURL
                && self.isReadyToPlay == videoItem.isReadyToPlay
    }

    override var hash: Int {
        return super.hash ^ self.fileURL!.hash
    }

    override var description: String {
        return "<\(self.dynamicType): fileURL=\(self.fileURL), isReadyToPlay=\(self.isReadyToPlay), appliesMediaViewMaskAsOutgoing=\(self.appliesMediaViewMaskAsOutgoing)>"
    }
    

    // pragma mark - NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.fileURL = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("fileURL"))) as! NSURL
        self.isReadyToPlay = aDecoder.decodeBoolForKey(NSStringFromSelector(Selector("isReadyToPlay")))
    }

    required override init() {
        super.init()
    }

    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.fileURL,
            forKey: NSStringFromSelector(Selector("fileURL")))
        aCoder.encodeBool(self.isReadyToPlay,
            forKey: NSStringFromSelector(Selector("isReadyToPlay")))
    }

    // pragma mark - NSCopying

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: VideoMediaItem = VideoMediaItem(
            fileURL:self.fileURL!,
            isReadyToPlay:self.isReadyToPlay)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}
