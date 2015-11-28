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
                SettingMenu(
                    displayName: "Username",
                    segueName: "settings.to.settings_username"),
                SettingMenu(
                    displayName: "Phone Number",
                    segueName: ""),
            ],
            [
                SettingMenu(
                    displayName: "Notifications and Sounds",
                    segueName: ""),
                SettingMenu(
                    displayName: "Privacy and Security",
                    segueName: ""),
                SettingMenu(
                    displayName: "Chat Settings",
                    segueName: ""),
            ],
            [
                SettingMenu(
                    displayName: "About",
                    segueName: ""),
                SettingMenu(
                    displayName: "Help",
                    segueName: ""),
            ],
        ]
    }
}