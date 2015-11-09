//
//  Message.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Message {
    
    var senderId: String;
    var senderDisplayName: String;
    var date: NSDate;
    var text: String;
    var isMediaMessage: Bool;
    
    
    init(senderId: String, senderDisplayName: String, date: NSDate, text: String) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.text = text
        self.isMediaMessage = false
    }
}