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

public protocol XMPPMessageManagerDelegate : NSObjectProtocol {
	func onMessage(
        sender: XMPPStream,
        didReceiveMessage message: XMPPMessage,
        from user: XMPPUserCoreDataStorageObject)
	func onPhoto(
        sender: XMPPStream,
        didReceivePhoto message: XMPPMessage,
        from user: XMPPUserCoreDataStorageObject)
	func onMessage(
        sender: XMPPStream,
        userIsComposing user: XMPPUserCoreDataStorageObject)
}

public class XMPPMessageManager: NSObject {
	public weak var delegate: XMPPMessageManagerDelegate?
	
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
            completeMessage.addAttributeWithName("from", stringValue: XMPPManager.sharedInstance.stream.myJID.bare())
    		completeMessage.addChild(body)
    		
    		sharedInstance.didSendMessageCompletionBlock = completion
    		XMPPManager.sharedInstance.stream.sendElement(completeMessage)
        } else {
            print("ERROR: Empty mesasge not sent.")
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
	
    public func loadArchivedMessagesFrom(jid jid: String, mediaCompletion: ((Void) -> Void)?) -> NSMutableArray {
		let moc = messageStorage?.mainThreadManagedObjectContext
		let entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		let request = NSFetchRequest()
		let predicateFormat = "bareJidStr like %@ "
		let predicate = NSPredicate(format: predicateFormat, jid)
		let retrievedMessages = NSMutableArray()
		
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
				
				let body: String
				let sender: String
				let date: NSDate
				
				date = message.timestamp
				
				if message.body() != nil {
					body = message.body()
				} else {
					body = ""
				}
				
				if element.attributeStringValueForName("to") == jid {
					let displayName = XMPPManager.sharedInstance.stream.myJID
					sender = displayName!.bare()
				} else {
					sender = jid
				}
                
                if let _ = element.elementForName("body")!.elementForName("photo") {
                    if let photoMessage = S3PhotoManager.sharedInstance.getPhotoMessage(element, completion: mediaCompletion) {
                        retrievedMessages.addObject(photoMessage)
                    } else {
                        print("Unable to load archive photo message")
                    }
                } else {
                    let fullMessage = Message(senderId: sender, senderDisplayName: sender, date: date, text: body)
                    retrievedMessages.addObject(fullMessage)
                }
			}
		} catch _ {
			//catch fetch error here
		}
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
		if let completion = XMPPMessageManager.sharedInstance.didSendMessageCompletionBlock {
			completion(stream: sender, message: message)
		}
	}
	
	// public func xmppStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage) {
    func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        print("didReceiveManager")
		if let user = XMPPManager.sharedInstance.rosterStorage.userForJID(
            message.from(),
            xmppStream: XMPPManager.sharedInstance.stream,
            managedObjectContext: XMPPRosterManager.sharedInstance.managedObjectContext_roster()) {
    
            // (1) User is in roster
                
    		if !XMPPChatManager.knownUserForJid(jidStr: user.jidStr) {
    			XMPPChatManager.addUserToChatList(jidStr: user.jidStr)
    		}
    		
    		if message.isChatMessageWithBody() {
                print("receiving message from \(user.jidStr) --> \(message.elementForName("body")!.stringValue())")
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
                print("composing by \(user.jidStr)")
    			if let _ = message.elementForName("composing") {
    				XMPPMessageManager.sharedInstance.delegate?.onMessage(sender, userIsComposing: user)
    			}
    		}
        }
        // (2) User is not in roster
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