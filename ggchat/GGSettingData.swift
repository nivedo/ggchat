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
                    id: "username",
                    displayName: "Username",
                    segueName: "settings.to.settings_textfield"),
                SettingMenu(
                    id: "phone_number",
                    displayName: "Phone Number",
                    segueName: ""),
            ],
            [
                SettingMenu(
                    id: "notification",
                    displayName: "Notifications and Sounds",
                    segueName: ""),
                SettingMenu(
                    id: "language",
                    displayName: "Language",
                    segueName: "settings.to.settings_language"),
                SettingMenu(
                    id: "chat",
                    displayName: "Chat Settings",
                    segueName: ""),
            ],
            [
                SettingMenu(
                    id: "about",
                    displayName: "About",
                    segueName: ""),
                SettingMenu(
                    id: "help",
                    displayName: "Help",
                    segueName: ""),
            ],
        ]
    }
}