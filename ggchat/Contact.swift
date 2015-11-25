//
//  Contact.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Contact {
    var id: String
    var displayName: String
    
    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}