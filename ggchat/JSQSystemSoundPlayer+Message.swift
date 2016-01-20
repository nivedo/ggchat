//
//  JSQSystemSoundPlayer+Message.swift
//  Blub
//
//  Created by Gary Chang on 12/1/15.
//  Copyright © 2015 Gary Chang. All rights reserved.
//

import Foundation
import JSQSystemSoundPlayer

let kJSQMessageReceivedSoundName: String = "message_received"
let kJSQMessageSentSoundName: String = "message_sent"

/*
extension NSBundle {
    
    class func jsq_messagesBundle() -> NSBundle {
        return NSBundle(forClass: MessageViewController.self)
    }
    
    class func jsq_messagesAssetBundle() -> NSBundle {
        let bundleResourcePath: String = NSBundle.jsq_messagesBundle().resourcePath!
        let assetPath = NSURL(fileURLWithPath: bundleResourcePath).URLByAppendingPathComponent("GGMessagesAssets.bundle").absoluteString
        return NSBundle(path: assetPath)!
    }
}
*/

extension JSQSystemSoundPlayer {
    class func jsq_playMessageReceivedSound() {
        self.jsq_playSoundFromJSQMessagesBundleWithName(kJSQMessageReceivedSoundName, asAlert: false)
    }

    class func jsq_playMessageReceivedAlert() {
        self.jsq_playSoundFromJSQMessagesBundleWithName(kJSQMessageReceivedSoundName, asAlert: true)
    }

    class func jsq_playMessageSentSound() {
        self.jsq_playSoundFromJSQMessagesBundleWithName(kJSQMessageSentSoundName, asAlert: false)
    }

    class func jsq_playMessageSentAlert() {
        self.jsq_playSoundFromJSQMessagesBundleWithName(kJSQMessageSentSoundName, asAlert: true)
    }

    private class func jsq_playSoundFromJSQMessagesBundleWithName(soundName: String, asAlert: Bool) {
        if !UserAPI.sharedInstance.settings.sound {
            return
        }
        
        //  save sound player original bundle
        let originalPlayerBundleIdentifier: String = JSQSystemSoundPlayer.sharedPlayer().bundle.bundleIdentifier!
        
        //  search for sounds in this library's bundle
        // JSQSystemSoundPlayer.sharedPlayer().bundle = NSBundle.gg_messagesBundle()
        JSQSystemSoundPlayer.sharedPlayer().bundle = NSBundle.gg_messagesAssetBundle()
        
        let fileName: String = "Sounds/\(soundName)"
        /*
        let fileNameAndType: String = NSBundle.gg_messagesAssetBundle().pathForResource(fileName, ofType: kJSQSystemSoundTypeAIF)!
        print("\(fileNameAndType) exists? = \(NSFileManager.defaultManager().fileExistsAtPath(fileNameAndType))")
        */
        if (asAlert) {
            JSQSystemSoundPlayer.sharedPlayer().playAlertSoundWithFilename(fileName, fileExtension: kJSQSystemSoundTypeAIFF, completion: nil)
        }
        else {
            JSQSystemSoundPlayer.sharedPlayer().playSoundWithFilename(fileName, fileExtension: kJSQSystemSoundTypeAIFF, completion: nil)
        }
        
        //  restore original bundle
        JSQSystemSoundPlayer.sharedPlayer().bundle = NSBundle(identifier:originalPlayerBundleIdentifier)!
    }
}