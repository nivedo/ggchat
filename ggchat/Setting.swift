//
//  Setting.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class SettingMenu {
    var id: String
    var displayName: String
    var segueName: String
    
    init(id: String, displayName: String, segueName: String) {
        self.id = id
        self.displayName = displayName
        self.segueName = segueName
    }
}