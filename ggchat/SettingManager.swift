//
//  SettingManager.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class SettingManager {

    var tappableMessageText: Bool = false
    
    class var sharedInstance: SettingManager {
        struct Singleton {
            static let instance = SettingManager()
        }
        return Singleton.instance
    }
    
}