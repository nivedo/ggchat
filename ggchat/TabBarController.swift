//
//  TabBarController.swift
//  ggchat
//
//  Created by Gary Chang on 1/8/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation
import JSQSystemSoundPlayer
// import AudioToolbox

class TabBarController {
    
    init() {
       // Nothing to do
    }
    
    class func incrementChatsBadge(tabBarController: UITabBarController?, increment: Int = 1) {
        JSQSystemSoundPlayer.jsq_playMessageReceivedAlert()
        // AudioServicesPlaySystemSound(1103)
        
        if let tabBarItems = tabBarController?.tabBar.items {
            if let badgeValue = tabBarItems[0].badgeValue, let badgeInt = Int(badgeValue) {
                tabBarItems[0].badgeValue = (badgeInt + increment).description
            } else {
                tabBarItems[0].badgeValue = "\(increment)"
            }
        }
    }
}