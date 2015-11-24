//
//  Chat.swift
//  ggchat
//
//  Created by Gary Chang on 11/20/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Chat {
    var chatId: String
    var chatDisplayName: String
    var recentMessage: String
    var recentUpdateTime: String
    
    init(chatId: String, chatDisplayName: String, recentMessage: String, recentUpdateTime: String) {
        self.chatId = chatId
        self.chatDisplayName = chatDisplayName
        self.recentMessage = recentMessage
        self.recentUpdateTime = recentUpdateTime
    }
}