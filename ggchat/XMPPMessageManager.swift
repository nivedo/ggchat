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
    /*
	func onMessage(
        sender: XMPPStream,
        didReceiveMessage message: XMPPMessage,
        from user: RosterUser) // XMPPUserCoreDataStorageObject)
	func onPhoto(
        sender: XMPPStream,
        didReceivePhoto message: XMPPMessage,
        from user: RosterUser) // XMPPUserCoreDataStorageObject)
	func onMessage(
        sender: XMPPStream,
        userIsComposing user: RosterUser) // XMPPUserCoreDataStorageObject)
    */
    
    func didSendMessage(
        sender: XMPPStream,
        message: XMPPMessage)
    func receiveMessage(from: String, message: Message)
    func receiveComposingMessage(from: String)
    
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
	public class func sendMessage(
        message: String,
        to receiver: String,
        completionHandler completion: MessageCompletionHandler?) {
        if (message.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            let messageId = XMPPManager.sharedInstance.stream.generateUUID()
            let body = DDXMLElement(name: "body", stringValue: message)
            let completeMessage = DDXMLElement(name: "message")
    		
    		completeMessage.addAttributeWithName("id", stringValue: messageId)
    		completeMessage.addAttributeWithName("type", stringValue: "chat")
    		completeMessage.addAttributeWithName("to", stringValue: receiver)
            completeMessage.addAttributeWithName("from", stringValue: UserAPI.sharedInstance.jidBareStr) // XMPPManager.sharedInstance.stream.myJID.bare())
    		completeMessage.addChild(body)
    		
    		sharedInstance.didSendMessageCompletionBlock = completion
            if XMPPManager.sharedInstance.isConnected() {
                print("XMPP connected, send message: \(message)")
                XMPPManager.sharedInstance.stream.sendElement(completeMessage)
            } else {
                print("XMPP not connected, message not sent and queued.")
            }
        } else {
            print("ERROR: Empty message not sent.")
        }
	}
    
    public class func sendPhoto(
        originalKey: String,
        thumbnailKey: String,
        to receiver: String,
        completionHandler completion: MessageCompletionHandler?) {
        
        let messageId = XMPPManager.sharedInstance.stream.generateUUID()
        let body = DDXMLElement(name: "body")
        let completeMessage = DDXMLElement(name: "message")
		
		completeMessage.addAttributeWithName("id", stringValue: messageId)
		completeMessage.addAttributeWithName("type", stringValue: "chat")
		completeMessage.addAttributeWithName("to", stringValue: receiver)
        completeMessage.addAttributeWithName("from", stringValue: XMPPManager.sharedInstance.stream.myJID.bare())
        let originalKey = DDXMLElement(name: "originalKey", stringValue: originalKey)
        let thumbnailKey = DDXMLElement(name: "thumbnailKey", stringValue: thumbnailKey)
        let photo = DDXMLElement(name: "photo")
		photo.addChild(originalKey)
		photo.addChild(thumbnailKey)
		body.addChild(photo)
        completeMessage.addChild(body)
           
        sharedInstance.didSendMessageCompletionBlock = completion
    	XMPPManager.sharedInstance.stream.sendElement(completeMessage)
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
    
    func archiveMessage(xmlString: String, date: NSDate, outgoing: Bool) {
        print("archiveMessage: \(xmlString)")
        var element: DDXMLElement?
        do {
            element = try DDXMLElement(XMLString: xmlString)
        } catch _ {
            element = nil
        }
      
        /*
        if let delay = DDXMLElement(name: "delay", xmlns: "urn:xmpp:delay") {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let timestamp = dateFormatter.stringFromDate(date)
            print("ARCHIVE DELAY: \(timestamp)")
            delay.addAttributeWithName("stamp", stringValue: timestamp)
            element?.addChild(delay)
        }
        */
        if let xmppMessage = XMPPMessage(fromElement: element) {
            self.messageStorage?.archiveMessage(xmppMessage,
                outgoing: outgoing,
                xmppStream: XMPPManager.sharedInstance.stream,
                archiveDate: date
            )
            
            print("archive SUCCESS")
        }
    }
	
    func loadArchivedMessagesFrom(jid jid: String, delegate: MessageMediaDelegate?) -> [Message] {
		let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ "
		let predicate = NSPredicate(format: predicateFormat, jid)
		var retrievedMessages = [Message]()
		
		request.predicate = predicate
		request.entity = entityDescription
		
		do {
			let results = try moc?.executeFetchRequest(request)
			
			for messageElement in results! {
                if let message = UserAPI.parseMessageFromString(
                    messageElement.messageStr,
                    date: messageElement.timestamp,
                    delegate: delegate) {
                    retrievedMessages.append(message)
                    // print("archived message: \(message.displayText)")
                }
			}
		} catch _ {
			//catch fetch error here
		}
        retrievedMessages.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        return retrievedMessages
	}
	
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
}

extension XMPPManager {
	
    func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        /*
        let errMsg = "Error Sending Message: " + error.debugDescription
        let mes = OPMessage(m: message)
        mes.fromSummoner = _loggedInUser
        delegate?.didFailSendMessage?(mes, errMsg : errMsg)
        */
    }
    
	func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        print("didSendMessage")
        XMPPMessageManager.sharedInstance.delegate?.didSendMessage(sender, message: message)
        
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
                XMPPMessageManager.sharedInstance.delegate?.receiveMessage(jid, message: msg)
                UserAPI.sharedInstance.newMessage(jid, date: now, message: msg)
            } else {
                print("Unable to parse received message \(message)")
            }
        } else {
            if let _ = message.elementForName("composing") {
                print("composing by \(jid)")
                XMPPMessageManager.sharedInstance.delegate?.receiveComposingMessage(jid)
            }
        }
            /*
            if let user = UserAPI.sharedInstance.rosterMap[message.from().bare()] {
        		if message.isChatMessageWithBody() {
                    print("receiving message from \(user.jid) --> \(message.elementForName("body")!.stringValue())")
                    if let _ = message.elementForName("body")!.elementForName("photo") {
            			XMPPMessageManager.sharedInstance.delegate?.onPhoto(sender,
                            didReceivePhoto: message,
                            from: user)
                    } else {
            			XMPPMessageManager.sharedInstance.delegate?.onMessage(sender,
                            didReceiveMessage: message,
                            from: user)
                    }
        		} else {
                    print("composing by \(user.jid)")
        			if let _ = message.elementForName("composing") {
        				XMPPMessageManager.sharedInstance.delegate?.onMessage(sender, userIsComposing: user)
        			}
        		}
            }
            */
	}
}

/*
extension XMPPMessage {
    
    func isChatMessageWithPhoto() -> Bool {
        if self.isChatMessage() {
            return self.elementForName("photo") != nil
        }
        return false
    }
}
*/