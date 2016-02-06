//
//  Message.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class Message {
   
    var toId: String
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
    var media: MessageMediaData?
    var id: String
    var readCount: Int = 0
    
    var isGroupChatEcho: Bool {
        get {
            return self.senderId == self.toId
        }
    }
    
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
    
    init(id: String, toId: String, fromId: String, senderId: String, date: NSDate, attributedText: NSAttributedString) {
        self.id = id
        self.toId = toId
        self.fromId = fromId
        self.senderId = senderId
        self.date = date
        self.attributedText = attributedText
        self.text = self.attributedText!.string
        self.rawText = self.text
        self.isMediaMessage = false
        self.isOutgoing = UserAPI.sharedInstance.isOutgoingJID(senderId)
    }
   
    init(id: String, toId: String, fromId: String, senderId: String, date: NSDate, media: MessageMediaData, attributedText: NSAttributedString? = nil) {
        self.id = id
        self.toId = toId
        self.fromId = fromId
        self.senderId = senderId
        self.isOutgoing = UserAPI.sharedInstance.isOutgoingJID(senderId)
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
    
    class func stripJID(jid: String, type: String) -> (String, String) {
        let tokens = jid.componentsSeparatedByString("/")
        if type == "groupchat" {
            if tokens.count >= 2 {
                return (tokens[0], tokens[1])
            } else {
                return (tokens[0], tokens[0])
            }
        } else {
            return (tokens[0], tokens[0])
        }
    }
    
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
    
    class func isGroupChatEchoMessage(element: DDXMLElement?) -> Bool {
        if let type = element?.attributeStringValueForName("type"),
            let from = element?.attributeStringValueForName("from") {
            if type == "groupchat" {
                let (_, senderId) = self.stripJID(from, type: type)
                if let to = element?.attributeStringValueForName("to") {
                    let toBare = UserAPI.stripResourceFromJID(to)
                    let jidBare = UserAPI.sharedInstance.jidBareStr
                    if (toBare == jidBare) && (senderId == jidBare) {
                        // Ignore group message sent by self
                        return true
                    }
                }
            }
        }
        return false
    }
    
    class func parseMessageFromElement(element: DDXMLElement?, date: NSDate, delegate: MessageMediaDelegate?) -> Message? {
        if let type = element?.attributeStringValueForName("type") {
            if type == "chat" || type == "groupchat" {
                if let bodyElement = element?.elementForName("body"),
                    let from = element?.attributeStringValueForName("from"),
                    let to = element?.attributeStringValueForName("to") {
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
                        }
                        let (fromId, senderId) = self.stripJID(from, type: type)
                        let toId = UserAPI.stripResourceFromJID(to)
                        
                        if let photo = bodyElement.elementForName("photo") {
                            let originalKey = photo.elementForName("originalKey")!.stringValue()
                            let thumbnailKey = photo.elementForName("thumbnailKey")!.stringValue()
                            
                            let photoMedia = PhotoMediaItem(thumbnailKey: thumbnailKey, originalKey: originalKey, delegate: delegate)
                            let photoMessage = Message(
                                id: id!,
                                toId: toId,
                                fromId: fromId,
                                senderId: senderId,
                                date: date,
                                media: photoMedia)
                            return photoMessage
                        } else {
                            let fullMessage = packet.message(id!,
                                toId: toId,
                                fromId: fromId,
                                senderId: senderId,
                                date: date,
                                delegate: delegate)
                            return fullMessage
                        }
                }
            } else if type == "normal" {
                if let xElement = element?.elementForName("x", xmlns: "http://jabber.org/protocol/muc#user"),
                    let inviteElement = xElement.elementForName("invite"),
                    let reasonElement = inviteElement.elementForName("reason") {
                        
                        let reason = reasonElement.stringValue()
                        var fromId: String!
                        var senderId: String!
                        var toId: String!
                        if let from = element?.attributeStringValueForName("from") {
                            fromId = UserAPI.stripResourceFromJID(from)
                            senderId = inviteElement.attributeStringValueForName("from")
                            toId = UserAPI.sharedInstance.jidBareStr
                        } else if let to = element?.attributeStringValueForName("to") {
                            fromId = UserAPI.stripResourceFromJID(to)
                            senderId = UserAPI.sharedInstance.jidBareStr
                            toId = inviteElement.attributeStringValueForName("to")
                        } else {
                            return nil
                        }
                        let id = "\(fromId):\(senderId)"
                        let packet = MessagePacket(placeholderText: reason, encodedText: reason)
                        let fullMessage = packet.message(id,
                            toId: toId,
                            fromId: fromId,
                            senderId: senderId,
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

class MessageVariable {
    var variableName: String
    var displayText: String
    var assetId: String
    var assetURL: String
    var placeholderURL: String?
    
    init(variableName: String, displayText: String, assetId: String, assetURL: String, placeholderURL: String?) {
        self.variableName = variableName
        self.displayText = displayText
        self.assetId = assetId
        self.assetURL = assetURL
        self.placeholderURL = placeholderURL
    }
}

class MessagePacket {
    static let delimiter = "__ggchat::link__"
    
    var placeholderText: String
    var encodedText: String
    var variables = [MessageVariable]()
    
    init(placeholderText: String, encodedText: String) {
        self.placeholderText = placeholderText
        self.encodedText = encodedText
    }
    
    var description: String {
        get {
            return self.encodedText
        }
    }
    
    var isSingleEncodedAsset: Bool {
        get {
            if self.variables.count == 1 {
                return self.encodedText == MessagePacket.delimiter
            }
            return false
        }
    }
    
    func getSingleEncodedAsset() -> GGWikiAsset? {
        // print("isSingleEncodedAsset: \(self.encodedText) --> \(self.isSingleEncodedAsset)")
        if self.isSingleEncodedAsset {
            let v = self.variables[0]
            return GGWiki.sharedInstance.addAsset(v.assetId, url: v.assetURL, displayName: v.displayText, placeholderURL: v.placeholderURL)
        }
        return nil
    }
    
    func message(id: String,
        toId: String,
        fromId: String,
        senderId: String,
        date: NSDate,
        delegate: MessageMediaDelegate?) -> Message {
            let isOutgoing = UserAPI.sharedInstance.isOutgoingJID(senderId)
            
            let attributedText = self.tappableText(isOutgoing ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor)
            if let asset = self.getSingleEncodedAsset() {
                let wikiMedia: WikiMediaItem = WikiMediaItem(imageURL: asset.url, placeholderURL: asset.placeholderURL, delegate: delegate)
                let message = Message(
                    id: id,
                    toId: toId,
                    fromId: fromId,
                    senderId: senderId,
                    date: date,
                    media: wikiMedia,
                    attributedText: attributedText)
                return message
            }
            let fullMessage = Message(
                id: id,
                toId: toId,
                fromId: fromId,
                senderId: senderId,
                date: date,
                attributedText: attributedText)
            
            return fullMessage
    }
    
    func tappableText(textColor: UIColor) -> NSAttributedString {
        let paragraph = NSMutableAttributedString(string: "")
        let tokens = self.encodedText.componentsSeparatedByString(MessagePacket.delimiter)
        if tokens.count == self.variables.count+1 {
            for (i, token) in tokens.enumerate() {
                if token.length > 0 {
                    let str = token
                    let attr: [String : NSObject] = [
                        NSFontAttributeName : GGConfig.messageBubbleFont,
                        NSForegroundColorAttributeName : textColor
                    ]
                    let attributedString = NSAttributedString(
                        string: str,
                        attributes: attr)
                    paragraph.appendAttributedString(attributedString)
                }
                if i < self.variables.count {
                    let variable = self.variables[i]
                    var attr: [String : NSObject] = [
                        NSFontAttributeName : GGConfig.messageBubbleFont,
                        NSForegroundColorAttributeName : textColor
                    ]
                    attr[TappableText.tapAttributeKey] = true
                    attr[TappableText.tapAssetId] = variable.assetId
                    attr[NSForegroundColorAttributeName] = UIColor.gg_highlightedColor()
                    
                    GGWiki.sharedInstance.addAsset(
                        variable.assetId,
                        url: variable.assetURL,
                        displayName: variable.displayText,
                        placeholderURL: variable.placeholderURL)
                    let attributedString = NSAttributedString(
                        string: variable.displayText,
                        attributes: attr)
                    paragraph.appendAttributedString(attributedString)
                }
            }
        } else {
            let str = self.placeholderText
            let attr: [String : NSObject] = [
                NSFontAttributeName : GGConfig.messageBubbleFont,
                NSForegroundColorAttributeName : textColor
            ]
            let attributedString = NSAttributedString(
                string: str,
                attributes: attr)
            paragraph.appendAttributedString(attributedString)
        }
        
        return paragraph.copy() as! NSAttributedString
    }
    
    func addVariable(variableName: String, displayText: String, assetId: String, assetURL: String, placeholderURL: String?) {
        self.variables.append(MessageVariable(
            variableName: variableName,
            displayText: displayText,
            assetId: assetId,
            assetURL: assetURL,
            placeholderURL: placeholderURL
            ))
    }
}
