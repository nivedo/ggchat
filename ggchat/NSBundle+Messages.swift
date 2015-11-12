//
//  NSBundle+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/9/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

extension NSBundle {
    class func gg_messagesBundle() -> NSBundle {
        return NSBundle(forClass: MessagesViewController.self)
    }
    
    class func gg_messagesAssetBundle() -> NSBundle {
        // let bundleResourcePath = NSBundle.gg_messagesBundle().resourcePath!
        let bundleResourcePath = NSBundle.mainBundle().resourcePath!
        // print(bundleResourcePath)
        let assetPath = NSURL(fileURLWithPath: bundleResourcePath).URLByAppendingPathComponent("GGMessagesAssets.bundle")
        // print(assetPath.absoluteString)
        return NSBundle(URL: assetPath)!
    }
    
    class func gg_localizedStringForKey(key: String) -> String {
        return NSLocalizedString(
            key,
            tableName:"GGMessages",
            bundle: NSBundle.gg_messagesAssetBundle(),
            value: "",
            comment: "")
    }

}