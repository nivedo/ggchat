//
//  GGSettingData.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class GGSettingData {
    
    class var sharedInstance: GGSettingData {
        struct Singleton {
            static let instance = GGSettingData()
        }
        return Singleton.instance
    }
   
    var menus: [[SettingMenu]]!
    
    init() {
        self.loadMenus()
    }
    
    func loadMenus() {
        self.menus = [
            [
                SettingMenu(displayName: "Profile"),
                SettingMenu(displayName: "Accounts"),
                SettingMenu(displayName: "Privacy"),
            ],
            [
                SettingMenu(displayName: "Notifications"),
                SettingMenu(displayName: "Themes"),
                SettingMenu(displayName: "Contacts"),
            ],
            [
                SettingMenu(displayName: "About"),
                SettingMenu(displayName: "Help"),
            ],
        ]
    }
}