//
//  Message.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Message: MessageData {
    
    var senderId: String
    var senderDisplayName: String
    var date: NSDate
    var text: String?
    var isMediaMessage: Bool
    var media: MessageMediaData?
    
    
    init(senderId: String, senderDisplayName: String, date: NSDate, text: String) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.text = text
        self.isMediaMessage = false
    }
    
    convenience init(senderId: String, senderDisplayName: String, text: String) {
        self.init(senderId: senderId,
            senderDisplayName: senderDisplayName,
            date: NSDate(),
            text: text)
    }
    
    init(senderId: String, senderDisplayName: String, date: NSDate, isMedia: Bool) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.isMediaMessage = isMedia
    }
    
    convenience init(senderId: String, senderDisplayName: String, date: NSDate, media: MessageMediaData) {
        self.init(senderId: senderId, senderDisplayName: senderDisplayName, date:date, isMedia: true)
        self.media = media
    }
    
    func messageHash() -> UInt {
        return self.hash()
    }
    
    func hash() -> UInt {
        let contentHash = self.text!.hash;
        return UInt(self.senderId.hash ^ self.date.hash ^ contentHash)
    }
}