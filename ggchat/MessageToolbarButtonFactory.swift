//
//  MessageToolbarButtonFactory.swift
//  ggchat
//
//  Created by Gary Chang on 11/18/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageToolbarButtonFactory {

    class func defaultAccessoryButtonItem() -> UIButton {
        let accessoryImage: UIImage = UIImage.gg_defaultAccessoryImage()
        let normalImage: UIImage = accessoryImage.gg_imageMaskedWithColor(UIColor.lightGrayColor())
        let highlightedImage: UIImage = accessoryImage.gg_imageMaskedWithColor(UIColor.darkGrayColor())

        let accessoryButton: UIButton = UIButton(frame: CGRectMake(0.0, 0.0, accessoryImage.size.width, 32.0))
        accessoryButton.setImage(normalImage, forState: UIControlState.Normal)
        accessoryButton.setImage(highlightedImage, forState: UIControlState.Highlighted)

        accessoryButton.contentMode = UIViewContentMode.ScaleAspectFit
        accessoryButton.backgroundColor = UIColor.clearColor()
        accessoryButton.tintColor = UIColor.lightGrayColor()

        return accessoryButton
    }

    class func defaultSendButtonItem() -> UIButton {
        let sendTitle: String = NSBundle.gg_localizedStringForKey("send")

        let sendButton: UIButton = UIButton(frame: CGRectZero)
        sendButton.setTitle(sendTitle, forState:UIControlState.Normal)
        sendButton.setTitleColor(UIColor.gg_messageBubbleBlueColor(), forState:UIControlState.Normal)
        sendButton.setTitleColor(UIColor.gg_messageBubbleBlueColor().gg_colorByDarkeningColorWithValue(0.1), forState: UIControlState.Highlighted)
        sendButton.setTitleColor(UIColor.lightGrayColor(), forState:UIControlState.Disabled)

        sendButton.titleLabel!.font = UIFont.boldSystemFontOfSize(16.0)
        sendButton.titleLabel!.adjustsFontSizeToFitWidth = true
        sendButton.titleLabel!.minimumScaleFactor = 0.7
        sendButton.contentMode = UIViewContentMode.Center
        sendButton.backgroundColor = UIColor.clearColor()
        sendButton.tintColor = UIColor.gg_messageBubbleBlueColor()

        let maxHeight: CGFloat = 32.0

        let sendTitleRect: CGRect = sendTitle.boundingRectWithSize(
            CGSizeMake(CGFloat.max, maxHeight),
            options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions.UsesLineFragmentOrigin.rawValue | NSStringDrawingOptions.UsesFontLeading.rawValue),
            attributes: [ NSFontAttributeName : sendButton.titleLabel!.font ],
            context:nil)

        print(CGRectGetWidth(CGRectIntegral(sendTitleRect)))
        sendButton.frame = CGRectMake(
            0.0,
            0.0,
            CGRectGetWidth(CGRectIntegral(sendTitleRect)),
            maxHeight)

        return sendButton
    }
}