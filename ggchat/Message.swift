//
//  Message.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Message {
    
    var senderId: String
    var senderDisplayName: String
    var date: NSDate
    private var text: String?
    var rawText: String?
    var attributedText: NSAttributedString?
    var isMediaMessage: Bool
    var isOutgoing: Bool
    var media: MessageMediaData?
    
    var displayText: String {
        get {
            if let text = self.attributedText?.string {
                return text
            } else {
                return "\(self.senderDisplayName) sent a media item."
            }
        }
    }
    
    init(senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, text: String) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.attributedText = TappableText.sharedInstance.tappableEncodedString(
            text,
            textColor: isOutgoing ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor)
        self.text = self.attributedText!.string
        self.rawText = text
        self.isMediaMessage = false
        self.isOutgoing = isOutgoing
    }
    
    convenience init(senderId: String, senderDisplayName: String, isOutgoing: Bool, text: String) {
        self.init(senderId: senderId,
            senderDisplayName: senderDisplayName,
            isOutgoing: isOutgoing,
            date: NSDate(),
            text: text)
    }
    
    init(senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, isMedia: Bool) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.isOutgoing = isOutgoing
        self.date = date
        self.isMediaMessage = isMedia
    }
    
    convenience init(senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, media: MessageMediaData, text: String? = nil) {
        self.init(
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            isOutgoing: isOutgoing,
            date: date,
            isMedia: true)
        self.media = media
        
        if let msg = text {
            self.attributedText = TappableText.sharedInstance.tappableEncodedString(
                msg,
                textColor: isOutgoing ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor)
        }
    }
    
    func addMedia(media: MessageMediaData) {
        self.media = media
        self.media!.setNeedsDisplay()
        self.isMediaMessage = true
    }
    
    func messageHash() -> Int {
        return self.hash()
    }
    
    func hash() -> Int {
        let contentHash = self.isMediaMessage ? self.media!.mediaHash() : self.text!.hash
        return Int(self.senderId.hash ^ self.date.hash ^ contentHash)
    }
}