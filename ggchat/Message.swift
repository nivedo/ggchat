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
    var id: String
    
    var displayText: String {
        get {
            if let text = self.attributedText?.string {
                return text
            } else {
                if self.senderId == UserAPI.sharedInstance.jidBareStr {
                    return "You sent a photo."
                } else {
                    return "\(self.senderDisplayName) sent a photo."
                }
            }
        }
    }
    
    init(id: String, senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, attributedText: NSAttributedString) {
        self.id = id
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.attributedText = attributedText
        self.text = self.attributedText!.string
        self.rawText = self.text
        self.isMediaMessage = false
        self.isOutgoing = isOutgoing
    }
   
    /*
    init(id: String, senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, text: String) {
        self.id = id
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
    */
   
    /*
    convenience init(id: String, senderId: String, senderDisplayName: String, isOutgoing: Bool, text: String) {
        self.init(
            id: id,
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            isOutgoing: isOutgoing,
            date: NSDate(),
            text: text)
    }
    */
    
    init(id: String, senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, isMedia: Bool) {
        self.id = id
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.isOutgoing = isOutgoing
        self.date = date
        self.isMediaMessage = isMedia
    }
    
    convenience init(id: String, senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, media: MessageMediaData, attributedText: NSAttributedString? = nil) {
        self.init(
            id: id,
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            isOutgoing: isOutgoing,
            date: date,
            isMedia: true)
        self.media = media
        
        self.attributedText = attributedText
    }
    
    func addMedia(media: MessageMediaData) {
        self.media = media
        self.media!.setNeedsDisplay()
        self.isMediaMessage = true
    }
    
    func setMediaDelegate(delegate: MessageMediaDelegate) {
        self.media?.setDelegate(delegate)
    }
    
    func messageHash() -> Int {
        return self.hash()
    }
    
    func hash() -> Int {
        let contentHash = self.isMediaMessage ? self.media!.mediaHash() : self.text!.hash
        return Int(self.senderId.hash ^ self.date.hash ^ contentHash)
    }
}