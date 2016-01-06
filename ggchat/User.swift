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
        return self.jid == rosterUser.jidBare &&
            self.nickname == rosterUser.nickname &&
            self.avatar == rosterUser.avatar
    }
    
    func update(rosterUser: RosterUser) -> Bool {
        if !self.isEqual(rosterUser) {
            self.nickname = rosterUser.nickname
            self.avatar = rosterUser.avatar
            return true
        }
        return false
    }
    
    func set(rosterUser: RosterUser) {
        self.jid = rosterUser.jidBare
        self.nickname = rosterUser.nickname
        self.avatar = rosterUser.avatar
    }

}
