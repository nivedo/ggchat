//
//  TabBarController.swift
//  ggchat
//
//  Created by Gary Chang on 1/8/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class TabBarController {
    
    init() {
       // Nothing to do
    }
    
    class func incrementChatsBadge(tabBarController: UITabBarController?) {
        if let tabBarItems = tabBarController?.tabBar.items {
            if let badgeValue = tabBarItems[0].badgeValue, let badgeInt = Int(badgeValue) {
                tabBarItems[0].badgeValue = (badgeInt + 1).description
            } else {
                tabBarItems[0].badgeValue = "1"
            }
        }
    }
}