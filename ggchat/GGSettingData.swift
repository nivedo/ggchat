//
//  GGSettingData.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class LanguageChoice {
    var native: String
    var english: String
    var language: String
    
    init(native: String, english: String, language: String) {
        self.native = native
        self.english = english
        self.language = language
    }
}

class NotificationMenu {
    var displayName: String
    var type: String
    var switchControl: UISwitch?
    
    init(displayName: String, type: String) {
        self.displayName = displayName
        self.type = type
    }
}

class GGSettingData {
    
    class var sharedInstance: GGSettingData {
        struct Singleton {
            static let instance = GGSettingData()
        }
        return Singleton.instance
    }
   
    var menus: [[SettingMenu]]!
    var languages: [LanguageChoice]!
    var notifications: [[NotificationMenu]]!
    
    init() {
        self.loadMenus()
        self.loadLanguages()
        self.loadNotifications()
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
                    segueName: "settings.to.settings_notification"),
                SettingMenu(
                    id: "language",
                    displayName: "Language",
                    segueName: "settings.to.settings_language"),
                /*
                SettingMenu(
                    id: "chat",
                    displayName: "Chat Settings",
                    segueName: ""),
                */
            ],
            [
                /*
                SettingMenu(
                    id: "about",
                    displayName: "About",
                    segueName: ""),
                SettingMenu(
                    id: "help",
                    displayName: "Help",
                    segueName: ""),
                */
                SettingMenu(
                    id: "logout",
                    displayName: "Log Out",
                    segueName: "settings.to.login"),
            ],
        ]
    }
    
    func loadLanguages() {
        self.languages = [
            LanguageChoice(
                native: "English",
                english: "English (US)",
                language: Language.English),
            LanguageChoice(
                native: "繁體中文",
                english: "Chinese Traditional",
                language: Language.ChineseTraditional),
            LanguageChoice(
                native: "简体中文",
                english: "Chinese Simplified",
                language: Language.ChineseSimplified),
            LanguageChoice(
                native: "日本語",
                english: "Japanese",
                language: Language.Japanese)
        ]
    }
    
    func loadNotifications() {
        self.notifications = [
            [
                NotificationMenu(displayName: "Alert", type: "switch"),
                NotificationMenu(displayName: "Message Preview", type: "switch"),
                NotificationMenu(displayName: "Sound", type: "menu"),
            ],
            [
                NotificationMenu(displayName: "In-App Sounds", type: "switch"),
                NotificationMenu(displayName: "In-App Vibrate", type: "switch"),
                NotificationMenu(displayName: "In-App Preview", type: "switch"),
            ],
        ]
    }
}