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
    var senderDisplayName: String {
        get {
            if self.isOutgoing {
                return UserAPI.sharedInstance.displayName
            } else {
                return UserAPI.sharedInstance.getDisplayName(self.senderId)
            }
        }
    }
    
    var date: NSDate
    private var text: String?
    var rawText: String?
    var attributedText: NSAttributedString?
    var isMediaMessage: Bool
    var isOutgoing: Bool
    var isComposing: Bool = false
    var isFailedToSend: Bool = false
    var media: MessageMediaData?
    var id: String
    var readCount: Int = 0
    var isInvitation: Bool = false
    
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
    
    init(id: String, senderId: String, isOutgoing: Bool, date: NSDate, attributedText: NSAttributedString) {
        self.id = id
        self.senderId = senderId
        self.date = date
        self.attributedText = attributedText
        self.text = self.attributedText!.string
        self.rawText = self.text
        self.isMediaMessage = false
        self.isOutgoing = isOutgoing
    }
   
    init(id: String, senderId: String, isOutgoing: Bool, date: NSDate, media: MessageMediaData, attributedText: NSAttributedString? = nil) {
        self.id = id
        self.senderId = senderId
        self.isOutgoing = isOutgoing
        self.date = date
        self.isMediaMessage = true
        self.media = media
        self.attributedText = attributedText
    }
    
    func markAsRead() {
        // print("mark as read --> \(self.attributedText)")
        self.readCount++
    }
    
    var isRead: Bool {
        get {
            return self.readCount > 0
        }
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