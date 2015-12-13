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
    var attributedText: NSAttributedString?
    var isMediaMessage: Bool
    var isOutgoing: Bool
    var media: MessageMediaData?
   
    /*
    func textAsAttributedStringForView(
        textColor: UIColor,
        attributes: [String: NSObject]?) -> NSAttributedString {
        return TappableText.sharedInstance.tappableAttributedString(
            self.text!, textColor: textColor, attributes: attributes)
    }
    */
    
    var displayText: String {
        get {
            // return self.text!
            return self.attributedText!.string
        }
    }
    
    init(senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, text: String) {
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.date = date
        self.attributedText = TappableText.sharedInstance.tappableAttributedString(
            text,
            textColor: isOutgoing ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor)
        self.text = self.attributedText!.string
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
    
    convenience init(senderId: String, senderDisplayName: String, isOutgoing: Bool, date: NSDate, media: MessageMediaData) {
        self.init(
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            isOutgoing: isOutgoing,
            date: date,
            isMedia: true)
        self.media = media
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