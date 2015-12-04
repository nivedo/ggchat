//
//  UIImage+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/9/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func gg_imageScaledToSize(size : CGSize, isOpaque : Bool) -> UIImage {
        
        // begin a context of the desired size
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
        
        // draw image in the rect with zero origin and size of the context
        let imageRect = CGRect(origin: CGPointZero, size: size)
        self.drawInRect(imageRect)
        
        // get the scaled image, close the context and return the image
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func gg_imageMaskedWithColor(maskColor: UIColor) -> UIImage {
        
        let imageRect = CGRectMake(0.0, 0.0, self.size.width, self.size.height)
        var newImage: UIImage? = nil
        
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()
            
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, 0.0, -(imageRect.size.height))
        
        CGContextClipToMask(context, imageRect, self.CGImage)
        CGContextSetFillColorWithColor(context, maskColor.CGColor)
        CGContextFillRect(context, imageRect)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    class func gg_bubbleImageFromBundleWithName(name: String) -> UIImage {
        let bundle = NSBundle.gg_messagesAssetBundle()
        let path = bundle.pathForResource(name, ofType:"png", inDirectory:"Images")!
        return UIImage(contentsOfFile: path)!
    }
    
    class func gg_bubbleRegularImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("bubble_regular")
    }
    
    class func gg_bubbleRegularTaillessImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("bubble_tailless")
    }
    
    class func gg_bubbleRegularStrokedImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("bubble_stroked")
    }
    
    class func gg_bubbleRegularStrokedTaillessImage() -> UIImage {
    return UIImage.gg_bubbleImageFromBundleWithName("bubble_stroked_tailless")
    }
    
    class func gg_bubbleCompactImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("bubble_min")
    }
    
    class func gg_bubbleCompactTaillessImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("bubble_min_tailless")
    }
    
    class func gg_defaultAccessoryImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("clip")
    }
    
    class func gg_defaultTypingIndicatorImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("typing")
    }
    
    class func gg_defaultPlayImage() -> UIImage {
        return UIImage.gg_bubbleImageFromBundleWithName("play")
    }
}
