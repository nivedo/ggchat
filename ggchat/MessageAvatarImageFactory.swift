//
//  MessageAvatarImageFactory.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit


class MessageAvatarImageFactory: NSObject {


    // pragma mark - Public

    class func avatarImageWithPlaceholder(placeholderImage: UIImage, diameter: CGFloat) -> MessageAvatarImage {
        let circlePlaceholderImage: UIImage = MessageAvatarImageFactory.gg_circularImage(placeholderImage,
            withDiameter: diameter,
            highlightedColor: nil)
        
        return MessageAvatarImage.avatarImageWithPlaceholder(circlePlaceholderImage)
    }
        
    class func avatarImageWithImage(image: UIImage, diameter: CGFloat) -> MessageAvatarImage {
        let avatar: UIImage = MessageAvatarImageFactory.circularAvatarImage(image, withDiameter:diameter)
        let highlightedAvatar: UIImage = MessageAvatarImageFactory.circularAvatarHighlightedImage(image, withDiameter:diameter)
        
        return MessageAvatarImage(avatarImage:avatar,
            highlightedImage: highlightedAvatar,
            placeholderImage: avatar)
        }
        
    class func circularAvatarImage(image: UIImage, withDiameter diameter: CGFloat) -> UIImage {
        return MessageAvatarImageFactory.gg_circularImage(image,
            withDiameter: diameter,
            highlightedColor:nil)
        }
        
    class func circularAvatarHighlightedImage(image: UIImage, withDiameter diameter: CGFloat) -> UIImage {
        return MessageAvatarImageFactory.gg_circularImage(image,
            withDiameter: diameter,
            highlightedColor: UIColor(white: 0.1, alpha:0.3))
    }
        
    class func avatarImageWithUserInitials(userInitials: String,
        backgroundColor: UIColor,
        textColor: UIColor,
        font: UIFont,
        diameter: CGFloat) -> MessageAvatarImage {
        let avatarImage: UIImage = MessageAvatarImageFactory.gg_imageWitInitials(userInitials,
            backgroundColor: backgroundColor,
            textColor: textColor,
            font: font,
            diameter: diameter)
        
        let avatarHighlightedImage: UIImage = MessageAvatarImageFactory.gg_circularImage(avatarImage,
            withDiameter: diameter,
            highlightedColor: UIColor(white: 0.1, alpha:0.3))
        
        return MessageAvatarImage(avatarImage: avatarImage,
            highlightedImage: avatarHighlightedImage,
            placeholderImage: avatarImage)
    }

    // pragma mark - Private

    class func gg_imageWitInitials(
        initials: String,
        backgroundColor: UIColor,
        textColor: UIColor,
        font: UIFont,
        diameter: CGFloat) -> UIImage {
        
        let frame: CGRect = CGRectMake(0.0, 0.0, diameter, diameter)
        
        let attributes: [String:AnyObject] = [
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : textColor ]
        
        let textFrame: CGRect = initials.boundingRectWithSize(frame.size,
            options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions.UsesLineFragmentOrigin.rawValue | NSStringDrawingOptions.UsesFontLeading.rawValue),
            attributes: attributes,
            context: nil)
        
        let frameMidPoint: CGPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        let textFrameMidPoint: CGPoint = CGPointMake(CGRectGetMidX(textFrame), CGRectGetMidY(textFrame))
        
        let dx: CGFloat = frameMidPoint.x - textFrameMidPoint.x
        let dy: CGFloat = frameMidPoint.y - textFrameMidPoint.y
        let drawPoint: CGPoint = CGPointMake(dx, dy)
        let image: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.mainScreen().scale)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor)
        CGContextFillRect(context, frame)
        initials.drawAtPoint(drawPoint, withAttributes:attributes)
        
        image = UIGraphicsGetImageFromCurrentImageContext()
            
        UIGraphicsEndImageContext()
        
        return MessageAvatarImageFactory.gg_circularImage(image!, withDiameter:diameter, highlightedColor:nil)
    }
    
    class func gg_circularImage(image: UIImage, withDiameter diameter: CGFloat, highlightedColor: UIColor?) -> UIImage {
        
        let frame: CGRect = CGRectMake(0.0, 0.0, diameter, diameter)
        var newImage: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.mainScreen().scale)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        
        let imgPath: UIBezierPath = UIBezierPath(ovalInRect:frame)
        imgPath.addClip()
        image.drawInRect(frame)
       
        if (highlightedColor != nil) {
            CGContextSetFillColorWithColor(context, highlightedColor!.CGColor)
            CGContextFillEllipseInRect(context, frame)
        }
        newImage = UIGraphicsGetImageFromCurrentImageContext()
            
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}