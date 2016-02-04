//
//  XMPPMessageManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/27/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias MessageCompletionHandler = (stream: XMPPStream, message: XMPPMessage) -> Void

// MARK: Protocols

protocol XMPPMessageManagerDelegate : NSObjectProtocol {
    func receiveMessage(from: String, message: Message)
    func receiveComposingMessage(from: String)
    func receiveReadReceipt(from: String, readReceipt: ReadReceipt)
    
    func didSendMessage(message: XMPPMessage)
    func didFailSendMessage(message: XMPPMessage)
}

extension XMPPMessageManagerDelegate {
    func didSendMessage(message: XMPPMessage) {
        // Optional implementation
    }
    
    func didFailSendMessage(message: XMPPMessage) {
        // Optional implementation
    }
}

public class XMPPMessageManager: NSObject {
	var delegate: XMPPMessageManagerDelegate?
	
	public var messageStorage: XMPPMessageArchivingCoreDataStorage?
	var messageArchiving: XMPPMessageArchiving?
	var didSendMessageCompletionBlock: MessageCompletionHandler?
	
	// MARK: Singleton
	
	public class var sharedInstance : XMPPMessageManager {
		struct XMPPMessageManagerSingleton {
			static let instance = XMPPMessageManager()
		}
		
		return XMPPMessageManagerSingleton.instance
	}
	
	// MARK: private methods
	
	func setupArchiving() {
		messageStorage = XMPPMessageArchivingCoreDataStorage.sharedInstance()
		messageArchiving = XMPPMessageArchiving(messageArchivingStorage: messageStorage)
		
		messageArchiving?.clientSideMessageArchivingOnly = true
		messageArchiving?.activate(XMPPManager.sharedInstance.stream)
		messageArchiving?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}
	
	// MARK: public methods
	class func sendMessage(
        id messageId: String,
        message messagePacket: MessagePacket,
        to receiver: String,
        date: NSDate,
        isOutgoing: Bool,
        completionHandler completion: MessageCompletionHandler?) {
        if (messagePacket.encodedText.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            // let messageId = XMPPManager.sharedInstance.stream.generateUUID()
            let body = DDXMLElement(name: "body", stringValue: messagePacket.placeholderText)
            let ggbody = DDXMLElement(name: "ggbody", stringValue: messagePacket.encodedText)
            let completeMessage = DDXMLElement(name: "message")
    		
    		completeMessage.addAttributeWithName("id", stringValue: messageId)
    		completeMessage.addAttributeWithName("type", stringValue: "chat")
            completeMessage.addAttributeWithName("content_type", stringValue: "text")
    		completeMessage.addAttributeWithName("to", stringValue: receiver)
            completeMessage.addAttributeWithName("from", stringValue: UserAPI.sharedInstance.jidBareStr) // XMPPManager.sharedInstance.stream.myJID.bare())
           
            let variablesElement = DDXMLElement(name: "variables")
            for variable in messagePacket.variables {
                let variableElement = DDXMLElement(name: "variable")
                variableElement.addAttributeWithName("name", stringValue: variable.variableName)
                variableElement.addAttributeWithName("displayText", stringValue: variable.displayText)
                variableElement.addAttributeWithName("assetId", stringValue: variable.assetId)
                variableElement.addAttributeWithName("assetURL", stringValue: variable.assetURL)
                if let placeholderURL = variable.placeholderURL {
                    variableElement.addAttributeWithName("placeholderURL", stringValue: placeholderURL)
                }
                variablesElement.addChild(variableElement)
            }
            ggbody.addChild(variablesElement)
    		completeMessage.addChild(body)
    		completeMessage.addChild(ggbody)
    		
    		sharedInstance.didSendMessageCompletionBlock = completion
            if XMPPManager.sharedInstance.stream.isAuthenticated() {
                print("XMPP connected, send message: \(messagePacket.description)")
                XMPPManager.sharedInstance.stream.sendElement(completeMessage)
            } else {
                print("XMPP not connected, message not sent and queued.")
                XMPPMessageManager.sharedInstance.archiveMessage(messageId, element: completeMessage, date: date, outgoing: isOutgoing, composing: true)
                /*
                if let m = completeMessage as? XMPPMessage {
                    XMPPMessageManager.sharedInstance.delegate?.didFailSendMessage(m)
                }
                */
            }
        } else {
            print("ERROR: Empty message not sent.")
        }
	}
    
    class func sendReadReceipt(
        ids: [String],
        to receiver: String) {
       
        let messageId = XMPPManager.sharedInstance.stream.generateUUID()
        let completeMessage = DDXMLElement(name: "message")
		completeMessage.addAttributeWithName("id", stringValue: messageId)
		completeMessage.addAttributeWithName("type", stringValue: "chat")
        completeMessage.addAttributeWithName("content_type", stringValue: "read_receipt")
		completeMessage.addAttributeWithName("to", stringValue: receiver)
        completeMessage.addAttributeWithName("from", stringValue: UserAPI.sharedInstance.jidBareStr)
       
        let receiptsElement = DDXMLElement(name: "receipts")
        for id in ids {
            let readElement = DDXMLElement(name: "read")
            readElement.addAttributeWithName("id", stringValue: id)
            receiptsElement.addChild(readElement)
        }
        let body = DDXMLElement(name: "body", stringValue: "__ggchat.read_receipt__") // Placeholder for core data archiving
		body.addChild(receiptsElement)
		completeMessage.addChild(body)
		
        if XMPPManager.sharedInstance.stream.isAuthenticated() {
            print("XMPP connected, send read receipt: \(ids.count)")
            XMPPManager.sharedInstance.stream.sendElement(completeMessage)
        } else {
            print("XMPP not connected, message not sent and queued.")
        }
    }
    
    public class func sendPhoto(
        id: String,
        originalKey: String,
        thumbnailKey: String,
        to receiver: String,
        queueInCoreData: Bool,
        completionHandler completion: MessageCompletionHandler?) {
        
        let messageId = id
        let body = DDXMLElement(name: "body", stringValue: "__gchat.photo__")
        let completeMessage = DDXMLElement(name: "message")
		
		completeMessage.addAttributeWithName("id", stringValue: messageId)
		completeMessage.addAttributeWithName("type", stringValue: "chat")
        completeMessage.addAttributeWithName("content_type", stringValue: "image")
		completeMessage.addAttributeWithName("to", stringValue: receiver)
        completeMessage.addAttributeWithName("from", stringValue: UserAPI.sharedInstance.jidBareStr) // XMPPManager.sharedInstance.stream.myJID.bare())
        let originalKey = DDXMLElement(name: "originalKey", stringValue: originalKey)
        let thumbnailKey = DDXMLElement(name: "thumbnailKey", stringValue: thumbnailKey)
        let photo = DDXMLElement(name: "photo")
		photo.addChild(originalKey)
		photo.addChild(thumbnailKey)
		body.addChild(photo)
        completeMessage.addChild(body)
         
        if !queueInCoreData && XMPPManager.sharedInstance.stream.isAuthenticated() {
            print("XMPP connected, send photo: \(id)")
            sharedInstance.didSendMessageCompletionBlock = completion
        	XMPPManager.sharedInstance.stream.sendElement(completeMessage)
        } else {
            print("XMPP not connected, queue photo: \(id)")
            XMPPMessageManager.sharedInstance.archiveMessage(messageId, element: completeMessage, date: NSDate(), outgoing: true, composing: true)
        }
	}
	
	public class func sendIsComposingMessage(recipient: String, completionHandler completion:MessageCompletionHandler) {
		if recipient.characters.count > 0 {
			let message = DDXMLElement.elementWithName("message") as! DDXMLElement
			message.addAttributeWithName("type", stringValue: "chat")
			message.addAttributeWithName("to", stringValue: recipient)
			
			let composing = DDXMLElement.elementWithName("composing", stringValue: "http://jabber.org/protocol/chatstates") as! DDXMLElement
			message.addChild(composing)
			
			sharedInstance.didSendMessageCompletionBlock = completion
			XMPPManager.sharedInstance.stream.sendElement(message)
		}
	}
    
    func archiveMessage(id: String, xmlString: String, date: NSDate, outgoing: Bool, composing: Bool = false) -> Bool {
        if self.archivedMessageIds.contains(id) {
            return false
        }
        
        print("archiveMessage: \(xmlString)")
        var element: DDXMLElement?
        do {
            element = try DDXMLElement(XMLString: xmlString)
        } catch _ {
            element = nil
        }
        
        return self.archiveMessage(id, element: element, date: date, outgoing: outgoing, composing: composing)
    }

    func archiveMessage(id: String, element: DDXMLElement?, date: NSDate, outgoing: Bool, composing: Bool) -> Bool {
        if self.archivedMessageIds.contains(id) {
            return false
        }
        
        if let xmppMessage = XMPPMessage(fromElement: element) {
            self.messageStorage?.archiveMessage(xmppMessage,
                outgoing: outgoing,
                xmppStream: XMPPManager.sharedInstance.stream,
                archiveDate: date,
                composing: composing,
                myJidStr: UserAPI.sharedInstance.jidBareStr,
                save: true
            )
            self.archivedMessageIds.insert(id)
            print("archive SUCCESS")
            return true
        }
        return false
    }
    
    func archiveMostRecentMessage(chat: ChatConversation, xmlString: String) {
        let jid = UserAPI.sharedInstance.jidBareStr
        if let msg = chat.lastMessage {
            self.messageStorage?.archiveMostRecentMessage(chat.peerJID,
                streamBareJidStr: jid,
                outgoing: msg.isOutgoing,
                archiveDate: chat.lastTime,
                messageStr: xmlString)
        }
    }
    
    var archivedMessageIds = Set<String>()

    func resendArchivedComposingMessagesFrom(jid: String) {
        if !XMPPManager.sharedInstance.stream.isAuthenticated() {
            return
        }
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ && composing == YES"
		let predicate = NSPredicate(format: predicateFormat, jid)
        
        request.predicate = predicate
		request.entity = entityDescription
		
		do {
			let results = try moc?.executeFetchRequest(request)
            var update = false
			for messageElement in results! {
                let xmppMessage = try XMPPMessage(XMLString: messageElement.messageStr)
                
                let xmppElement = xmppMessage as DDXMLElement
                if let body = xmppElement.elementForName("body"),
                    let id = xmppElement.attributeStringValueForName("id"),
                    let to = xmppElement.attributeStringValueForName("to"),
                    let photo = body.elementForName("photo"),
                    let originalKey = photo.elementForName("originalKey").stringValue(),
                    let thumbnailKey = photo.elementForName("thumbnailKey").stringValue()
                {
                    S3PhotoManager.sharedInstance.resendPhoto(id, to: to, originalKey: originalKey, thumbnailKey: thumbnailKey)
                } else {
                    XMPPManager.sharedInstance.stream.sendElement(xmppMessage)
                }

                moc!.deleteObject(messageElement as! NSManagedObject)
                // messageElement.setValue(false, forKey: "isComposing")
                
                update = true
            }
            print("Resent \(results!.count) composing messages in core data")
            if update {
                try moc!.save()
            }
        } catch _ {
            
        }
    }
    
    func loadMoreAchivedMessagesFrom(jid: String, firstDate: NSDate, delegate: MessageMediaDelegate?) -> [Message] {
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "(bareJidStr like %@) AND (timestamp < %@)"
		let predicate = NSPredicate(format: predicateFormat, jid, firstDate)
		var messages = [Message]()
        
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sort]
        request.fetchLimit = GGConfig.paginationLimit
        request.predicate = predicate
		request.entity = entityDescription
        
 		do {
			let results = try moc?.executeFetchRequest(request)
		
            print("Fetched \(results!.count) archived messages from core data.")
            
            // var composingCount = 0
			for messageElement in results! {
                
                self.hasMoreMessagesToLoad = (results!.count == GGConfig.paginationLimit)
                
                if let message = UserAPI.parseMessageFromString(
                    messageElement.messageStr,
                    date: messageElement.timestamp,
                    delegate: delegate) {
                    /*
                    if let composing = messageElement.isComposing {
                        message.isFailedToSend = composing
                        if composing {
                            composingCount++
                        }
                    }
                    */
                    messages.append(message)
                    self.archivedMessageIds.insert(message.id)
                /*
                } else if let readReceipt = UserAPI.parseReadReceiptFromString(messageElement.messageStr) {
                    receipts.append(readReceipt)
                */
                } else {
                    print("Unable to parse \(messageElement.messageStr)")
                }
               
                // print("---> composing: \(messageElement.isComposing)")
                // assert(!messageElement.isComposing, "Found composing \(messageElement)")
			}
            // print("Loaded \(composingCount) composing messages from core data")
		} catch _ {
			//catch fetch error here
		}
        messages.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })       
        return messages
    }
    
    var hasMoreMessagesToLoad: Bool = true
    
    func loadArchivedMessagesFrom(jid jid: String, delegate: MessageMediaDelegate?) -> ([Message], [ReadReceipt]) {
        self.hasMoreMessagesToLoad = true
        self.resendArchivedComposingMessagesFrom(jid)
        
		let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ "
		let predicate = NSPredicate(format: predicateFormat, jid)
		var messages = [Message]()
        var receipts = [ReadReceipt]()
        
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sort]
        request.fetchLimit = GGConfig.paginationLimit
        request.predicate = predicate
		request.entity = entityDescription
		
		do {
			let results = try moc?.executeFetchRequest(request)
		
            self.archivedMessageIds.removeAll()
            print("Fetched \(results!.count) archived messages from core data.")
            self.hasMoreMessagesToLoad = (results!.count == GGConfig.paginationLimit)
            
            var composingCount = 0
			for messageElement in results! {
                if let message = UserAPI.parseMessageFromString(
                    messageElement.messageStr,
                    date: messageElement.timestamp,
                    delegate: delegate) {
                    if let composing = messageElement.isComposing {
                        message.isFailedToSend = composing
                        if composing {
                            composingCount++
                        }
                    }
                    messages.append(message)
                    self.archivedMessageIds.insert(message.id)
                } else if let readReceipt = UserAPI.parseReadReceiptFromString(messageElement.messageStr) {
                    // print("Loaded archived read receipt: \(readReceipt.ids.count)")
                    receipts.append(readReceipt)
                } else {
                    print("Unable to parse \(messageElement.messageStr)")
                }
               
                // print("---> composing: \(messageElement.isComposing)")
                // assert(!messageElement.isComposing, "Found composing \(messageElement)")
			}
            print("Loaded \(composingCount) composing messages from core data")
		} catch _ {
			//catch fetch error here
		}
        messages.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        return (messages, receipts)
	}
    
    func deleteAllArchivedMessages() {
        print("Deleting all archived messages from core data")
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entityDescription
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let persist = messageStorage?.persistentStoreCoordinator
            try persist?.executeRequest(deleteRequest, withContext: moc!)
            // try moc?.save()
        } catch let error as NSError {
            print("Error deleting archived message core data: \(error)")
        }
    }
    
    func deleteAllContactMessages() {
        print("Deleting all contacts from core data")
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Contact_CoreDataObject", inManagedObjectContext: moc!)
        /*
        let request = NSFetchRequest()
		request.entity = entityDescription
       
        do {
			let results = try moc?.executeFetchRequest(request)
			
			for contactObject in results! {
                moc?.deleteObject(contactObject as! NSManagedObject)
			}
            try moc?.save()
		} catch _ {
			//catch fetch error here
		}
        */
		let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entityDescription
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let persist = messageStorage?.persistentStoreCoordinator
            try persist?.executeRequest(deleteRequest, withContext: moc!)
            // try moc?.save()
        } catch let error as NSError {
            print("Error deleting contact message core data: \(error)")
        }
    }
    
    func clearCoreData() {
        self.deleteAllContactMessages()
        self.deleteAllArchivedMessages()
    }
   
    func clearCoreDataFor(jid: String) {
        self.deleteContactMessageFrom(jid)
        self.deleteArchivedMessagesFrom(jid)
    }
    
    func deleteContactMessageFrom(jid: String) {
        print("Deleting contact from \(jid) in core data")
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Contact_CoreDataObject", inManagedObjectContext: moc!)
        
        let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ "
		let predicate = NSPredicate(format: predicateFormat, jid)
        
        request.predicate = predicate
		request.entity = entityDescription
	
        do {
			let results = try moc?.executeFetchRequest(request)
           
            var update = false
			for messageElement in results! {
                moc?.deleteObject(messageElement as! NSManagedObject)
                update = true
			}
            if update {
                try moc?.save()
            }
		} catch _ {
			//catch fetch error here
		}
    }
    
    func deleteArchivedMessagesFrom(jid: String) {
        let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ "
		let predicate = NSPredicate(format: predicateFormat, jid)
        
        request.predicate = predicate
		request.entity = entityDescription
	
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
		do {
            let persist = messageStorage?.persistentStoreCoordinator
            try persist?.executeRequest(deleteRequest, withContext: moc!)
            /*
			let results = try moc?.executeFetchRequest(request)
            self.archivedMessageIds.removeAll()
           
            var update = false
			for messageElement in results! {
                moc?.deleteObject(messageElement as! NSManagedObject)
                update = true
			}
            if update {
                try moc?.save()
            }
            */
		} catch _ {
			//catch fetch error here
		}
    }
    
    /*
	public func deleteMessagesFrom(jid jid: String, messages: NSArray) {
		messages.enumerateObjectsUsingBlock { (message, idx, stop) -> Void in
			let moc = self.messageStorage?.mainThreadManagedObjectContext
			let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
			let request = NSFetchRequest()
			let predicateFormat = "messageStr like %@ "
			let predicate = NSPredicate(format: predicateFormat, message as! String)
			
			request.predicate = predicate
			request.entity = entityDescription
			
			do {
				let results = try moc?.executeFetchRequest(request)
				
				for message in results! {
					var element: DDXMLElement!
					do {
						element = try DDXMLElement(XMLString: message.messageStr)
					} catch _ {
						element = nil
					}
					
					if element.attributeStringValueForName("messageStr") == message as! String {
						moc?.deleteObject(message as! NSManagedObject)
					}
				}
			} catch _ {
				//catch fetch error here
			}
		}
	}
    */
    
    func loadAllMostRecentArchivedMessages() -> [String: ChatConversation] {
		let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		request.entity = entityDescription
        
        var chatsMap = [String: ChatConversation]()
		
		do {
			let results = try moc?.executeFetchRequest(request)
			
			for messageObject in results! {
                let jid = UserAPI.stripResourceFromJID(messageObject.bareJidStr)
                if let chat = chatsMap[jid] {
                    chat.updateIfMoreRecent(messageObject.timestamp, xmlString: messageObject.messageStr)
                } else {
                    chatsMap[jid] = ChatConversation(jid: jid, date: messageObject.timestamp, xmlString: messageObject.messageStr)
                }
			}
		} catch _ {
			//catch fetch error here
		}
        return chatsMap
	}
    
    func loadAllContacts() -> [String: ChatConversation] {
		let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Contact_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		request.entity = entityDescription
       
        var chatsMap = [String: ChatConversation]()
        do {
			let results = try moc?.executeFetchRequest(request)
			
			for contactObject in results! {
                let jid = contactObject.bareJid.description
                let messageStr = contactObject.mostRecentMessageBody
                if let chat = chatsMap[jid] {
                    chat.updateIfMoreRecent(contactObject.mostRecentMessageTimestamp, xmlString: messageStr)
                } else {
                    chatsMap[jid] = ChatConversation(jid: jid, date: contactObject.mostRecentMessageTimestamp,
                        xmlString: messageStr)
                }
			}
		} catch _ {
			//catch fetch error here
		}
        return chatsMap
    }
}

extension XMPPManager {
	
    func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        print("didFailSendMessage")
        XMPPMessageManager.sharedInstance.delegate?.didFailSendMessage(message)
    }
    
	func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        print("didSendMessage")
        
        XMPPMessageManager.sharedInstance.delegate?.didSendMessage(message)
		if let completion = XMPPMessageManager.sharedInstance.didSendMessageCompletionBlock {
			completion(stream: sender, message: message)
		}
	}
	
	// public func xmppStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage) {
    func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        print("didReceiveMessage")
     
        let now = NSDate()
        let jid = UserAPI.stripResourceFromJID(message.from().bare())
        if message.isChatMessageWithBody() {
            if let msg = UserAPI.parseMessageFromElement(message as DDXMLElement, date: now, delegate: nil) {
                let chat = UserAPI.sharedInstance.newMessage(jid, date: now, message: msg)
                chat.incrementUnread()
                XMPPMessageManager.sharedInstance.delegate?.receiveMessage(jid, message: msg)
            } else if let readReceipt = UserAPI.parseReadReceiptFromElement(message as DDXMLElement) {
                // print("Received read receipts from \(readReceipt.from)")
                XMPPMessageManager.sharedInstance.delegate?.receiveReadReceipt(jid, readReceipt: readReceipt)
            } else {
                print("Unable to parse received message \(message)")
            }
        } else {
            if let _ = message.elementForName("composing") {
                print("composing by \(jid)")
                XMPPMessageManager.sharedInstance.delegate?.receiveComposingMessage(jid)
            }
        }
	}
}

extension XMPPMessage {
    
    func isChatInvite() -> Bool {
        if let type = self.attributeStringValueForName("type") {
            if type == "normal" {
                if let xElement = self.elementForName("x", xmlns: "http://jabber.org/protocol/muc#user"),
                    let _ = xElement.elementForName("invite") {
                    return true
                }
            }
        }
        return false
    }
    
}