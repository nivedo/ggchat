//
//  User.swift
//  ggchat
//
//  Created by Gary Chang on 1/6/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation
import CoreData


class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    func isEqual(rosterUser: RosterUser) -> Bool {
        return self.jid == rosterUser.jid &&
            self.nickname == rosterUser.nickname &&
            self.avatar == rosterUser.avatar &&
            self.is_buddy?.boolValue == rosterUser.isBuddy &&
            self.is_group?.boolValue == rosterUser.isGroup
    }
    
    func update(rosterUser: RosterUser) -> Bool {
        if !self.isEqual(rosterUser) {
            self.nickname = rosterUser.nickname
            self.avatar = rosterUser.avatar
            self.is_buddy = NSNumber(bool: rosterUser.isBuddy)
            self.is_group = NSNumber(bool: rosterUser.isGroup)
            return true
        }
        return false
    }
    
    func set(rosterUser: RosterUser) {
        self.jid = rosterUser.jid
        self.nickname = rosterUser.nickname
        self.avatar = rosterUser.avatar
        self.is_buddy = NSNumber(bool: rosterUser.isBuddy)
        self.is_group = NSNumber(bool: rosterUser.isGroup)
    }
}