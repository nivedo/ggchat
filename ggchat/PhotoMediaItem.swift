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
    
    var cachedImageView: UIImageView?

    // pragma mark - Initialization

    init(image: UIImage) {
        super.init()
        self.image = image.copy() as! UIImage
        self.cachedImageView = nil
    }

    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedImageView = nil
    }

    // pragma mark - Setters

    var image: UIImage? {
        didSet {
            self.cachedImageView = nil
        }
    }

    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            self.cachedImageView = nil
        }
    }

    // pragma mark - MessageMediaData protocol

    override func mediaView() -> UIView? {
        if (self.image == nil) {
            return nil
        }
        
        if (self.cachedImageView == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let imageView: UIImageView = UIImageView(image: self.image)
            imageView.frame = CGRectMake(0.0, 0.0, size.width, size.height)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            MessageMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(
                imageView,
                isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedImageView = imageView
        }
        
        return self.cachedImageView
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
}
