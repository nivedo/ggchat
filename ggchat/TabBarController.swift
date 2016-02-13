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
    
    class func incrementChatsBadge(tabBarController: UITabBarController?, message: Message, increment: Int = 1) {
        if message.isGroupChatEcho {
            return
        }
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

    class func updateChatsBar(tabBarController: UITabBarController?) {
        var totalUnread = 0
        for (_, chat) in UserAPI.sharedInstance.chatsMap {
            totalUnread += chat.unreadCount
        }
        self.updateChatsBadge(tabBarController, badge: totalUnread)
    }
    
    class func updateChatsBadge(tabBarController: UITabBarController?, badge: Int) {
        // AudioServicesPlaySystemSound(1103)
        
        if let tabBarItems = tabBarController?.tabBar.items {
            if badge == 0 {
                tabBarItems[0].badgeValue = nil
            } else {
                if let oldValue = tabBarItems[0].badgeValue, let oldInt = Int(oldValue) {
                    if badge > oldInt {
                        JSQSystemSoundPlayer.jsq_playMessageReceivedAlert()
                    }
                }
                tabBarItems[0].badgeValue = "\(badge)"
            }
        }
    }
}