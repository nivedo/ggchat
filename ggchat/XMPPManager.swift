//
//  XMPPManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/26/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias StreamCompletionHandler = (stream: XMPPStream, error: DDXMLElement?) -> Void

public protocol XMPPManagerDelegate {
    func onStream(sender: XMPPStream?, socketDidConnect socket: GCDAsyncSocket?)
    func onStreamDidConnect(sender: XMPPStream)
    func onStreamDidAuthenticate(sender: XMPPStream)
    func onStream(sender: XMPPStream, didNotAuthenticate error: DDXMLElement)
    func onStreamDidDisconnect(sender: XMPPStream, withError error: NSError)
}

class XMPPManager: NSObject,
    XMPPStreamDelegate,
    XMPPRosterDelegate {

    var username: String!
    var password: String!
    var domain: String!
    var stream: XMPPStream = XMPPStream()
    var roster: XMPPRoster!
    var rosterStorage: XMPPRosterCoreDataStorage = XMPPRosterCoreDataStorage()
    // var rosterStorage: XMPPRosterMemoryStorage = XMPPRosterMemoryStorage()
    var reconnecter: XMPPReconnect!
    var deliveryReceipts: XMPPMessageDeliveryReceipts!
    var capabilities: XMPPCapabilities!
    var capabilitiesStorage: XMPPCapabilitiesCoreDataStorage!
    
    // Delegates and completion handlers
    var delegate: XMPPManagerDelegate?
    var connectCompletionHandler: StreamCompletionHandler?
    var authenticateCompletionHandler: StreamCompletionHandler?
   
    //////////////////////////////////////////////////////////////////////////////
    // Initialization
    //////////////////////////////////////////////////////////////////////////////
    
    class var sharedInstance: XMPPManager {
        struct Singleton {
            static let instance = XMPPManager()
        }
        return Singleton.instance
    }
    
    class func start() {
        sharedInstance.setup()
    }
    
    class func stop() {
        sharedInstance.teardown()
    }
    
    func setup() {
        self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
        
        // Initialize delegates
        self.stream.addDelegate(self,
            delegateQueue: dispatch_get_main_queue())
        self.roster.autoFetchRoster = true
        self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        self.roster.activate(self.stream)
       
        // Initialize reconnector
        self.reconnecter = XMPPReconnect(dispatchQueue: dispatch_get_main_queue())
        self.reconnecter.usesOldSchoolSecureConnect = true
        self.reconnecter.activate(self.stream)
       
        // Initialize message delivery receipts
        self.deliveryReceipts = XMPPMessageDeliveryReceipts(dispatchQueue: dispatch_get_main_queue())
        self.deliveryReceipts.autoSendMessageDeliveryReceipts = true
        self.deliveryReceipts.autoSendMessageDeliveryRequests = true
        self.deliveryReceipts.activate(self.stream)
        
        // Initialize capabilities
        self.capabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
        self.capabilities = XMPPCapabilities(capabilitiesStorage: self.capabilitiesStorage)
        self.capabilities.autoFetchHashedCapabilities = true
        self.capabilities.autoFetchNonHashedCapabilities = false
        self.capabilities.activate(self.stream)
    }
    
    func teardown() {
        self.stream.removeDelegate(self)
        self.roster.removeDelegate(self)
        
        self.reconnecter.deactivate()
        self.roster.deactivate()
        self.capabilities.deactivate()

        self.stream.disconnect()
    }

    //////////////////////////////////////////////////////////////////////////////
    
    func login(username: String, password: String, domain: String,
        connectCompletionHandler: StreamCompletionHandler?,
        authenticateCompletionHandler: StreamCompletionHandler?) {
        self.username = username
        self.password = password
        self.domain = domain
       
        self.connectCompletionHandler = connectCompletionHandler
        self.authenticateCompletionHandler = authenticateCompletionHandler
            
        self.connect()
    }
  
    func isConnected() -> Bool {
        return self.stream.isConnected()
    }
    
    func connect() {
        self.stream.myJID = XMPPJID.jidWithUser(
            self.username,
            domain: self.domain,
            resource: "ios")
        // self.stream.myJID = XMPPJID.jidWithString("gchang@chat.blub.io")
        // self.stream.hostName = "45.33.39.21"
        
        if (self.stream.isConnected()) {
            // Already connected
            if (self.stream.isAuthenticated()) {
                print("Error: Already logged in. Please logout before attempting another login.")
            } else {
                self.xmppStreamDidConnect(self.stream)
            }
        } else {
            do {
                print("Connecting with \(self.username)@\(self.domain)")
                // try self.stream.oldSchoolSecureConnectWithTimeout(30.0)
                // var error: NSError? = nil
                try self.stream.connectWithTimeout(5) // XMPPStreamTimeoutNone)
            }
            catch {
                print("ERROR: Unable to connect to \(self.username)@\(self.domain)")
            }
        }
    }
   
    func xmppStream(sender: XMPPStream, willSecureWithSettings settings:NSMutableDictionary) {
        print("willSecureWithSettings")
        settings[GCDAsyncSocketManuallyEvaluateTrust] = true
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
        print("SUCCESS: Connect to \(self.username)@\(self.domain)")
        print("Attempting to Login")
        do {
            try self.stream.authenticateWithPassword(self.password)
        }
        catch{
            let errMsg = "Error Authenticating"
            print(errMsg)
            // delegate?.didFailLogin?(errMsg)
        }
        self.connectCompletionHandler?(stream: sender, error: nil)
    }
    
    func xmppStreamConnectDidTimeout(sender: XMPPStream!) {
        let errMsg = "Timed Out"
        print(errMsg)
        // delegate?.didFailLogin?(errMsg)
        
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("Error: " + error.stringValue())
        
    }
    
    func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        print("didDisconnect error: \(error)")
        
        self.stream.myJID = nil
        // delegate?.didLogout?()
        
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("Logged In Successfully\n")
        
        sender.sendElement(XMPPPresence())
        
        // delegate?.didLogin?()
        self.authenticateCompletionHandler?(stream: sender, error: nil)
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveIQ iq: XMPPIQ!) -> Bool {
        print("stream::didReceiveIQ")
        return false
    }
    
    //////////////////////////////////////////////////////////////////////////////
    // XMPPRosterDelegate
    //////////////////////////////////////////////////////////////////////////////
    
    func xmppRoster(sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        print("roster::didReceivePresenceSubscriptionRequest")
    }
    
    /**
    * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
    **/
    func xmppRoster(sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        print("roster::didReceiveRosterPush")
    }
    
    /**
    * Sent when the initial roster is received.
    **/
    func xmppRosterDidBeginPopulating(sender: XMPPRoster, withVersion version: String) {
        print("roster::didBeginPopulating")
    }
    
    /**
    * Sent when the initial roster has been populated into storage.
    **/
    func xmppRosterDidEndPopulating(sender: XMPPRoster) {
        print("roster::didEndPopulating")
        
        // let population = self.rosterStorage.
    }
    
    /**
    * Sent when the roster receives a roster item.
    *
    * Example:
    *
    * <item jid='romeo@example.net' name='Romeo' subscription='both'>
    *   <group>Friends</group>
    * </item>
    **/
    func xmppRoster(sender: XMPPRoster,
        didReceiveRosterItem item: DDXMLElement!) {
        print("roster::didReceiveRosterItem")
    }
    
    //////////////////////////////////////////////////////////////////////////////
    // XMPPStreamDelegate
    //////////////////////////////////////////////////////////////////////////////
    
    func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        /*
        let errMsg = "Error Sending Message: " + error.debugDescription
        let mes = OPMessage(m: message)
        mes.fromSummoner = _loggedInUser
        delegate?.didFailSendMessage?(mes, errMsg : errMsg)
        */
    }
    
    func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        /*
        let mes = OPMessage(m: message)
        mes.fromSummoner = _loggedInUser
        delegate?.didSendMessage?(mes)
        */
    }
    
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        let errMsg = "Error: " + error.stringValue()
        print(errMsg)
        // delegate?.didFailLogin?(errMsg)
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
        print("didReceiveMessage")
        if (message.isChatMessageWithBody()) {
            if let user: XMPPUserCoreDataStorageObject = self.rosterStorage.userForJID(
                message.from(),
                xmppStream: self.stream,
                managedObjectContext: self.managedObjectContextForRoster) {
                let body: String = message.elementForName("body")!.stringValue()
                let displayName: String = user.displayName
                
                print("message received: \(displayName) --> \(body)")
            } else {
                print("message sender \(message.from()) not in roster")
            }
        }
    }
    
    func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        print("didReceivePresence from \(presence.fromStr())")
        let presenceType = presence.type()
        let presenceFromJID = presence.fromStr()
        
        if (self.stream.myJID.bare() != presenceFromJID) {
            if (presenceType == "available") {
                print("\(presenceFromJID) is \(presenceType)")
            } else if (presenceType == "unavailable") {
                print("\(presenceFromJID) is \(presenceType)")
            } else if (presenceType == "subscribe") {
                print("\(presenceFromJID) wants to subscribe")
                var accept: Bool = true
                if (accept) {
                    self.roster.acceptPresenceSubscriptionRequestFrom(
                        presence.from(),
                        andAddToRoster: true)
                } else {
                    self.roster.rejectPresenceSubscriptionRequestFrom(
                        presence.from())
                }
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////
    // XMPPManager public interface
    //////////////////////////////////////////////////////////////////////////////
   
    var managedObjectContextForRoster: NSManagedObjectContext {
        get {
            return self.rosterStorage.mainThreadManagedObjectContext
        }
    }
    
    func fetchResultsControllerForRoster(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController {
        let moc: NSManagedObjectContext = self.managedObjectContextForRoster
        
        let entity: NSEntityDescription = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: moc)!
        
        let sd1: NSSortDescriptor = NSSortDescriptor(key: "sectionNum", ascending: true)
        let sd2: NSSortDescriptor = NSSortDescriptor(key: "displayName", ascending: true)
        
        let sortDescriptors: [NSSortDescriptor] = [sd1, sd2]
        
        let fetchRequest: NSFetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = 10
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest:fetchRequest,
            managedObjectContext: moc,
            sectionNameKeyPath: "sectionNum",
            cacheName:nil)
        fetchedResultsController.delegate = delegate
        
       
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
        return fetchedResultsController
    }

    func sendMessage(jidStr: String, message: String) {
        if (message.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            let messageId = self.stream.generateUUID()
            let messageText = DDXMLElement(name: "body", stringValue: message)
            let messageElement = DDXMLElement(name: "message")
            messageElement.addAttributeWithName("to", stringValue: jidStr)
            messageElement.addAttributeWithName("from", stringValue: self.stream.myJID.bare())
            messageElement.addAttributeWithName("type", stringValue: "chat")
            messageElement.addAttributeWithName("id", stringValue: messageId)
            messageElement.addChild(messageText)
            self.stream.sendElement(messageElement)
        } else {
            print("ERROR: Empty message not sent.")
        }
    }
    
    func sendSubscriptionRequestForRoster(jidStr: String) {
        let jid = XMPPJID.jidWithString(jidStr)
        self.roster.addUser(jid, withNickname: nil)
    }
}