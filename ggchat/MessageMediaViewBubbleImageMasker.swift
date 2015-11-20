//
//  MessageMediaViewBubbleImageMasker.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageMediaViewBubbleImageMasker {

    // pragma mark - Initialization
    let bubbleImageFactory = MessageBubbleImageFactory()

    // pragma mark - View masking

    func applyOutgoingBubbleImageMaskToMediaView(mediaView: UIView) {
        let bubbleImageData: MessageBubbleImage = self.bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.whiteColor())
        self.gg_maskView(mediaView,
            withImage: bubbleImageData.messageBubbleImage)
    }

    func applyIncomingBubbleImageMaskToMediaView(mediaView: UIView) {
        let bubbleImageData: MessageBubbleImage = self.bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.whiteColor())
        self.gg_maskView(mediaView,
            withImage: bubbleImageData.messageBubbleImage)
    }

    class func applyBubbleImageMaskToMediaView(mediaView: UIView, isOutgoing: Bool) {
        let masker: MessageMediaViewBubbleImageMasker = MessageMediaViewBubbleImageMasker()
        
        if (isOutgoing) {
            masker.applyOutgoingBubbleImageMaskToMediaView(mediaView)
        }
        else {
            masker.applyIncomingBubbleImageMaskToMediaView(mediaView)
        }
    }

    // pragma mark - Private
    private func gg_maskView(view: UIView, withImage image: UIImage) {
        let imageViewMask: UIImageView = UIImageView(image: image)
        imageViewMask.frame = CGRectInset(view.frame, 2.0, 2.0)
        
        view.layer.mask = imageViewMask.layer
    }
}