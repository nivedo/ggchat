//
//  UIDevice+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    class func gg_isCurrentDeviceBeforeiOS8() -> Bool {
        // iOS < 8.0
        return UIDevice.currentDevice().systemVersion.compare("8.0", options:NSStringCompareOptions.NumericSearch) == .OrderedAscending;
    }
}