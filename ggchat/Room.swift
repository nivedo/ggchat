//
//  Room.swift
//  ggchat
//
//  Created by Gary Chang on 11/20/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Room {
    var roomId: String
    var roomDisplayName: String
    var recentMessage: String
    var recentUpdateTime: String
    
    init(roomId: String, roomDisplayName: String, recentMessage: String, recentUpdateTime: String) {
        self.roomId = roomId
        self.roomDisplayName = roomDisplayName
        self.recentMessage = recentMessage
        self.recentUpdateTime = recentUpdateTime
    }
}