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
    // Class helper methods
    //////////////////////////////////////////////////////////////////////////////

    class var senderId: String {
        get {
            if (sharedInstance.isConnected()) {
                return sharedInstance.stream.myJID.bare()
            } else {
                if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.jid) {
                    return previousJID
                } else {
                    return GGKey.jid
                }
            }
        }
    }
    
    class var senderDisplayName: String {
        get {
            if (sharedInstance.isConnected()) {
                return sharedInstance.stream.myJID.bare()
            } else {
                if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.displayName) {
                    return previousJID
                } else {
                    return GGKey.displayName
                }
            }
        }
    }
    
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
        
        XMPPRosterManager.sharedInstance.fetchedResultsController()?.delegate = XMPPRosterManager.sharedInstance
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
        self.roster.autoAcceptKnownPresenceSubscriptionRequests = true
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
        // print("SUCCESS: Connect to \(self.username)@\(self.domain)")
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
       
        // Save jid and displayName
        NSUserDefaults.standardUserDefaults().setValue(self.stream.myJID.bare(),
            forKey: GGKey.jid)
        NSUserDefaults.standardUserDefaults().setValue(self.stream.myJID.bare(),
            forKey: GGKey.displayName)
        NSUserDefaults.standardUserDefaults().synchronize()
    
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

   
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        let errMsg = "Error: " + error.stringValue()
        print(errMsg)
        // delegate?.didFailLogin?(errMsg)
    }


    //////////////////////////////////////////////////////////////////////////////
    // XMPPManager public interface
    //////////////////////////////////////////////////////////////////////////////
    
    func sendSubscriptionRequestForRoster(jidStr: String) {
        let jid = XMPPJID.jidWithString(jidStr)
        self.roster.addUser(jid, withNickname: nil)
    }
}