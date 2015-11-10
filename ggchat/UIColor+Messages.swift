//
//  UIColor+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/9/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func gg_messageBubbleGreenColor() -> UIColor {
        return UIColor(
            hue:130.0 / 360.0,
            saturation:0.68,
            brightness:0.84,
            alpha:1.0)
    }
    
    class func gg_messageBubbleBlueColor() -> UIColor {
        return UIColor(
            hue: 210.0 / 360.0,
            saturation: 0.94,
            brightness: 1.0,
            alpha: 1.0)
    }
    
    class func gg_messageBubbleRedColor() -> UIColor {
        return UIColor(
            hue: 0.0 / 360.0,
            saturation: 0.79,
            brightness: 1.0,
            alpha: 1.0)
    }
    
    class func gg_messageBubbleLightGrayColor() -> UIColor {
        return UIColor(
            hue: 240.0 / 360.0,
            saturation: 0.02,
            brightness: 0.92,
            alpha: 1.0)
    }
    
    func gg_colorByDarkeningColorWithValue(value: CGFloat) -> UIColor {
        let totalComponents = CGColorGetNumberOfComponents(self.CGColor)
        let isGreyscale = (totalComponents == 2) ? true : false
        
        let buffer = UnsafeBufferPointer(start: CGColorGetComponents(self.CGColor), count: 4)
        let oldComponents = Array(buffer)
        var newComponents = Array<CGFloat>(count: 4, repeatedValue: 0)
        
        if (isGreyscale) {
            newComponents[0] = oldComponents[0] - value < 0.0 ? 0.0 : oldComponents[0] - value
            newComponents[1] = oldComponents[0] - value < 0.0 ? 0.0 : oldComponents[0] - value
            newComponents[2] = oldComponents[0] - value < 0.0 ? 0.0 : oldComponents[0] - value
            newComponents[3] = oldComponents[1]
        } else {
            newComponents[0] = oldComponents[0] - value < 0.0 ? 0.0 : oldComponents[0] - value
            newComponents[1] = oldComponents[1] - value < 0.0 ? 0.0 : oldComponents[1] - value
            newComponents[2] = oldComponents[2] - value < 0.0 ? 0.0 : oldComponents[2] - value
            newComponents[3] = oldComponents[3]
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let newColor = CGColorCreate(colorSpace, newComponents)
        
        let retColor = UIColor(CGColor:newColor!)
        return retColor;
    }

}