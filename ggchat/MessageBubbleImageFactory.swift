//
//  MessageBubbleImageFactory.swift
//  ggchat
//
//  Created by Gary Chang on 11/9/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageBubbleImageFactory: NSObject {
   
    var bubbleImage: UIImage
    var capInsets: UIEdgeInsets
    
    init(bubbleImage: UIImage, capInsets: UIEdgeInsets) {
        self.bubbleImage = bubbleImage
        if (UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
            self.capInsets = MessageBubbleImageFactory.gg_centerPointEdgeInsetsForImageSize(bubbleImage.size)
        } else {
            self.capInsets = capInsets
        }
    }
    
    convenience init(bubbleImage: UIImage) {
        self.init(bubbleImage: bubbleImage, capInsets: UIEdgeInsetsZero)
    }
    
    func outgoingMessagesBubbleImageWithColor(color: UIColor) -> MessageBubbleImage {
        return self.gg_messagesBubbleImageWithColor(color, flippedForIncoming: false)
    }
    
    func incomingMessagesBubbleImageWithColor(color: UIColor) -> MessageBubbleImage {
        return self.gg_messagesBubbleImageWithColor(color, flippedForIncoming: true)
    }
   
    class func gg_centerPointEdgeInsetsForImageSize(bubbleImageSize: CGSize) -> UIEdgeInsets {
        // make image stretchable from center point
        let center: CGPoint = CGPointMake(bubbleImageSize.width / 2.0, bubbleImageSize.height / 2.0)
        return UIEdgeInsetsMake(center.y, center.x, center.y, center.x)
    }
    
    func gg_messagesBubbleImageWithColor(color: UIColor, flippedForIncoming: Bool) -> MessageBubbleImage {
        var  normalBubble = self.bubbleImage.gg_imageMaskedWithColor(color)
        var highlightedBubble = self.bubbleImage.gg_imageMaskedWithColor(
            color.gg_colorByDarkeningColorWithValue(0.12))
        
        if (flippedForIncoming) {
            normalBubble = self.gg_horizontallyFlippedImageFromImage(normalBubble)
            highlightedBubble = self.gg_horizontallyFlippedImageFromImage(highlightedBubble)
        }
        
        normalBubble = self.gg_stretchableImageFromImage(normalBubble, withCapInsets: self.capInsets)
        highlightedBubble = self.gg_stretchableImageFromImage(highlightedBubble, withCapInsets: self.capInsets)
        
        return MessageBubbleImage(image: normalBubble, highlightedImage:highlightedBubble)
    }
    
    func gg_horizontallyFlippedImageFromImage(image: UIImage) -> UIImage {
        return UIImage(CGImage:image.CGImage!,
            scale: image.scale,
            orientation: UIImageOrientation.UpMirrored)
    }
    
    func gg_stretchableImageFromImage(image: UIImage, withCapInsets capInsets: UIEdgeInsets) -> UIImage {
        return image.resizableImageWithCapInsets(capInsets, resizingMode:UIImageResizingMode.Stretch)
    }
}