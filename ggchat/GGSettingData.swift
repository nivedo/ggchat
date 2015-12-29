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

class GGSettingData {
    
    class var sharedInstance: GGSettingData {
        struct Singleton {
            static let instance = GGSettingData()
        }
        return Singleton.instance
    }
   
    var menus: [[SettingMenu]]!
    var languages: [LanguageChoice]!
    
    init() {
        self.loadMenus()
        self.loadLanguages()
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
}