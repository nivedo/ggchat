//
//  Message.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Message {
   
    var fromId: String
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
    var isInvitation: Bool = false
    var isGroupChat: Bool = false
    var media: MessageMediaData?
    var id: String
    var readCount: Int = 0
    
    var displayText: String {
        get {
            if let text = self.attributedText?.string {
                return text
            } else {
                if self.isOutgoing {
                    return "You sent a photo."
                } else {
                    return "\(self.senderDisplayName) sent a photo."
                }
            }
        }
    }
    
    init(id: String, senderId: String, isOutgoing: Bool, date: NSDate, attributedText: NSAttributedString) {
        self.id = id
        self.fromId = senderId
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
        self.fromId = senderId
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
    
    ////////////////////////////////////////////////////////////////////////
    
    class func parseMessageFromString(xmlString: String, timestamp: NSTimeInterval, delegate: MessageMediaDelegate?) -> Message? {
        let date: NSDate = NSDate(timeIntervalSince1970: timestamp)
        return self.parseMessageFromString(xmlString, date: date, delegate: delegate)
    }
    
    class func parseMessageFromString(xmlString: String, date: NSDate, delegate: MessageMediaDelegate?) -> Message? {
        var element: DDXMLElement?
        do {
            element = try DDXMLElement(XMLString: xmlString)
        } catch _ {
            element = nil
        }
        
        return self.parseMessageFromElement(element, date: date, delegate: delegate)
    }
    
    class func parseVariablesFromElement(element: DDXMLElement?) -> [MessageVariable] {
        var variablesArray = [MessageVariable]()
        if let variablesElement = element?.elementForName("variables") {
            let variables = variablesElement.elementsForName("variable")
            for variableElement in variables {
                let name = variableElement.attributeStringValueForName("name")
                let displayText = variableElement.attributeStringValueForName("displayText")
                let assetId = variableElement.attributeStringValueForName("assetId")
                let assetURL = variableElement.attributeStringValueForName("assetURL")
                let placeholderURL = variableElement.attributeStringValueForName("placeholderURL")
                variablesArray.append(MessageVariable(variableName: name, displayText: displayText, assetId: assetId, assetURL: assetURL, placeholderURL: placeholderURL))
            }
        }
        return variablesArray
    }
    
    class func parseMessageFromElement(element: DDXMLElement?, date: NSDate, delegate: MessageMediaDelegate?) -> Message? {
        if let type = element?.attributeStringValueForName("type") {
            if type == "chat" || type == "groupchat" {
                if let bodyElement = element?.elementForName("body"),
                    let from = element?.attributeStringValueForName("from") {
                        if let content_type = element?.attributeStringValueForName("content_type") {
                            if content_type == "read_receipt" {
                                return nil
                            }
                        }
                        
                        let id = element?.attributeStringValueForName("id")
                        
                        let text = bodyElement.stringValue()
                        let packet = MessagePacket(placeholderText: text, encodedText: text)
                        if let ggbodyElement = element?.elementForName("ggbody") {
                            packet.encodedText = ggbodyElement.stringValue()
                            packet.variables = self.parseVariablesFromElement(ggbodyElement)
                            // print("parsed \(variables.count) variables")
                        }
                        let fromBare = UserAPI.stripResourceFromJID(from)
                        
                        if let photo = bodyElement.elementForName("photo") {
                            let originalKey = photo.elementForName("originalKey")!.stringValue()
                            let thumbnailKey = photo.elementForName("thumbnailKey")!.stringValue()
                            
                            let photoMedia = PhotoMediaItem(thumbnailKey: thumbnailKey, originalKey: originalKey, delegate: delegate)
                            let photoMessage = Message(
                                id: id!,
                                senderId: fromBare,
                                isOutgoing: UserAPI.sharedInstance.isOutgoingJID(fromBare),
                                date: date,
                                media: photoMedia)
                            return photoMessage
                        } else {
                            // let encodeTime = NSDate()
                            let fullMessage = packet.message(id!,
                                senderId: fromBare,
                                date: date,
                                delegate: delegate)
                            // let elapsedTime1 = NSDate().timeIntervalSinceDate(startTime)
                            // let elapsedTime2 = NSDate().timeIntervalSinceDate(encodeTime)
                            // print("parse body: \(text), time1: \(elapsedTime1), time2: \(elapsedTime2)")
                            return fullMessage
                        }
                }
            } else if type == "normal" {
                if let xElement = element?.elementForName("x", xmlns: "http://jabber.org/protocol/muc#user"),
                    let inviteElement = xElement.elementForName("invite"),
                    let reasonElement = inviteElement.elementForName("reason") {
                        
                        let reason = reasonElement.stringValue()
                        var fromBare: String!
                        var inviter: String!
                        if let from = element?.attributeStringValueForName("from") {
                            inviter = inviteElement.attributeStringValueForName("from")
                            fromBare = UserAPI.stripResourceFromJID(from)
                        } else if let _ = element?.attributeStringValueForName("to") {
                            inviter = inviteElement.attributeStringValueForName("to")
                            fromBare = UserAPI.sharedInstance.jidBareStr
                        } else {
                            return nil
                        }
                        let id = "\(fromBare):\(inviter)"
                        let packet = MessagePacket(placeholderText: reason, encodedText: reason)
                        let fullMessage = packet.message(id,
                            senderId: fromBare,
                            date: date,
                            delegate: delegate)
                        fullMessage.isInvitation = true
                        return fullMessage
                }
            }
        }
        return nil
    }
}