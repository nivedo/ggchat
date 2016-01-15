//
//  XMPPManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/26/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias StreamCompletionHandler = (stream: XMPPStream, error: String?) -> Void

protocol XMPPManagerDelegate {
    func onAuthenticate()
}

class XMPPManager: NSObject,
    XMPPStreamDelegate,
    XMPPReconnectDelegate {
    // XMPPRosterDelegate {
    // XMPPvCardTempModuleDelegate {

    var username: String!
    var password: String!
    var jid_: String?
    var domain: String = GGSetting.xmppDomain
    var stream: XMPPStream!
    // var roster: XMPPRoster!
    // var rosterStorage: XMPPRosterCoreDataStorage = XMPPRosterCoreDataStorage()
    // var rosterStorage: XMPPRosterMemoryStorage = XMPPRosterMemoryStorage()
    var reconnecter: XMPPReconnect!
    var deliveryReceipts: XMPPMessageDeliveryReceipts!
    var capabilities: XMPPCapabilities!
    var capabilitiesStorage: XMPPCapabilitiesCoreDataStorage!
    // var vCardStorage: XMPPvCardCoreDataStorage!
    // var vCardTempModule: XMPPvCardTempModule!
    // var vCardAvatarModule: XMPPvCardAvatarModule!
    // var lastActivity: XMPPLastActivity!
    
    // Delegates and completion handlers
    var delegate: XMPPManagerDelegate?
    var connectCompletionHandler: StreamCompletionHandler?
    var authenticateCompletionHandler: StreamCompletionHandler?
   
    //////////////////////////////////////////////////////////////////////////////
    // Class helper methods
    //////////////////////////////////////////////////////////////////////////////
 
    var jid: String {
        get {
            if self.jid_ == nil {
                if (self.isConnected()) {
                    return self.stream.myJID.bare()
                } else {
                    if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.jid) {
                        return previousJID
                    } else {
                        return GGKey.jid
                    }
                }
            } else {
                return self.jid_!
            }
        }
        set {
            self.jid_ = newValue
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
        
        XMPPMessageManager.sharedInstance.setupArchiving()
    }
    
    class func refresh() {
        sharedInstance.reconnectIfNotConnected()
    }
    
    class func stop() {
        sharedInstance.teardown()
    }
    
    func setup() {
        self.stream = XMPPStream()
        
        #if !TARGET_IPHONE_SIMULATOR
            self.stream.enableBackgroundingOnSocket = true
        #endif
        
        // self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
        
        // Initialize delegates
        self.stream.addDelegate(self,
            delegateQueue: dispatch_get_main_queue())
        /*
        self.roster.autoFetchRoster = true
        self.roster.autoAcceptKnownPresenceSubscriptionRequests = true
        self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        self.roster.activate(self.stream)
        */
        
        // Initialize reconnector
        self.reconnecter = XMPPReconnect(dispatchQueue: dispatch_get_main_queue())
        self.reconnecter.usesOldSchoolSecureConnect = false // true
        self.reconnecter.addDelegate(self, delegateQueue: dispatch_get_main_queue())
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
        
        /*
        // Initialize vCard support
        self.vCardStorage = XMPPvCardCoreDataStorage.sharedInstance()
        self.vCardTempModule = XMPPvCardTempModule(withvCardStorage: self.vCardStorage)
        self.vCardAvatarModule = XMPPvCardAvatarModule(withvCardTempModule: self.vCardTempModule)
        self.vCardTempModule.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        self.vCardTempModule.activate(self.stream)
        self.vCardAvatarModule.activate(self.stream)
        
        // Initialize last activity
        self.lastActivity = XMPPLastActivity()
        self.lastActivity.activate(self.stream)
        self.lastActivity.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        */
    }
    
    func teardown() {
        self.stream.removeDelegate(self)
        // self.roster.removeDelegate(self)
        // self.vCardTempModule.removeDelegate(self)
        // self.lastActivity.removeDelegate(self)
        
        self.reconnecter.deactivate()
        // self.roster.deactivate()
        self.capabilities.deactivate()
        // self.vCardTempModule.deactivate()
        // self.vCardAvatarModule.deactivate()
        // self.lastActivity.deactivate()

        self.stream.disconnect()
    }

    //////////////////////////////////////////////////////////////////////////////

    
    func isConnected() -> Bool {
        return self.stream.isConnected()
    }
    
    func isOutgoingJID(jid: String) -> Bool {
        return jid == UserAPI.sharedInstance.jidStr // self.stream.myJID.bare()
    }
    
    func reconnectIfNotConnected() {
        if !self.isConnected() {
            self.connectWithJID(
                jid: nil,
                password: nil,
                connectCompletionHandler: nil,
                authenticateCompletionHandler: nil)
        }
    }
    
    func connectWithJID(
        jid jidOrNil: String?,
        password passwordOrNil: String?,
        connectCompletionHandler: StreamCompletionHandler?,
        authenticateCompletionHandler: StreamCompletionHandler?) {
            
        self.connectCompletionHandler = connectCompletionHandler
        self.authenticateCompletionHandler = authenticateCompletionHandler
           
        if self.stream.isConnecting() {
            return
        }
        if (self.stream.isConnected()) {
            // Already connected
            print("XMPP stream already connected")
            if !self.stream.isAuthenticated() {
                self.xmppStreamDidConnect(self.stream)
            } else {
                self.xmppStreamDidAuthenticate(self.stream)
            }
            return
        }
     
        // Set jid
        if (jidOrNil == nil) {
            if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.jid) {
                self.jid = previousJID
            } else {
                print("Error: Please enter jid before trying to connect.")
                return
            }
        } else {
            self.jid = jidOrNil!
        }
            
        // Set password
        if (passwordOrNil == nil) {
            if let previousPassword = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.password) {
                self.password = previousPassword
            } else {
                print("Error: Please enter password before trying to connect.")
                return
            }
        } else {
            self.password = passwordOrNil!
        }
       
        self.stream.myJID = XMPPJID.jidWithString(
            self.jid,
            resource: "ios")
        
        do {
            print("Connecting with \(jid)")
            // try self.stream.oldSchoolSecureConnectWithTimeout(30.0)
            // var error: NSError? = nil
            try self.stream.connectWithTimeout(5) // XMPPStreamTimeoutNone)
        }
        catch {
            print("ERROR: Unable to connect to \(jid)")
        }
    }
   
    func xmppStream(sender: XMPPStream, willSecureWithSettings settings:NSMutableDictionary) {
        print("willSecureWithSettings")
        settings[GCDAsyncSocketManuallyEvaluateTrust] = true
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
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
        let errMsg = "Timed Out."
        print(errMsg)
        self.connectCompletionHandler?(stream: sender, error: errMsg)
        
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("didReceiveError: " + error.stringValue())
        
        // self.authenticateCompletionHandler?(stream: sender, error: "Password incorrect")
    }
    
    func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        print("didDisconnect error: \(error)")
        
        self.stream.myJID = nil
        // delegate?.didLogout?()
        
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("Logged In Successfully\n")
        
        sender.sendElement(XMPPPresence())
      
        // Save usernmae
        // NSUserDefaults.standardUserDefaults().setValue(self.username, forKey: GGKey.username)
        // NSUserDefaults.standardUserDefaults().setValue(self.password, forKey: GGKey.password)
        
        // Save jid and displayName
        NSUserDefaults.standardUserDefaults().setValue(self.stream.myJID.bare(),
            forKey: GGKey.jid)
        NSUserDefaults.standardUserDefaults().setValue(self.stream.myJID.bare(),
            forKey: GGKey.displayName)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Fetch vCard
        // self.vCardTempModule.fetchvCardTempForJID(self.stream.myJID)
    
        self.authenticateCompletionHandler?(stream: sender, error: nil)
        self.delegate?.onAuthenticate()
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveIQ iq: XMPPIQ!) -> Bool {
        print("stream::didReceiveIQ")
        return false
    }
    
    //////////////////////////////////////////////////////////////////////////////
    // XMPPRosterDelegate
    //////////////////////////////////////////////////////////////////////////////
   
    /*
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
    */
    
    //////////////////////////////////////////////////////////////////////////////
    // XMPPStreamDelegate
    //////////////////////////////////////////////////////////////////////////////
   
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        let errMsg = "didNotAuthenticate: " + error.stringValue()
        print(errMsg)
        self.stream.disconnect()
        self.authenticateCompletionHandler?(stream: sender, error: "Username or password incorrect")
    }

    //////////////////////////////////////////////////////////////////////////////
    // XMPPReconnectDelegate
    //////////////////////////////////////////////////////////////////////////////

    func xmppReconnect(sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkConnectionFlags) {
        print("didDetectAccidentalDisconnect")
        // XMPPManager.sharedInstance.stream.asyncDisconnect()
    }

    func xmppReconnect(sender: XMPPReconnect!, shouldAttemptAutoReconnect connectionFlags: SCNetworkConnectionFlags) -> Bool {
        let shouldReconnect = ConnectionManager.isConnectedToNetwork()
        print("shouldAttemptAutoReconnect: \(shouldReconnect)")
        self.stream.myJID = XMPPJID.jidWithString(UserAPI.sharedInstance.jidBareStr,
            resource: "ios")
        /*
        do {
            try self.stream.connectWithTimeout(5)
        } catch let error as NSError {
            print(error)
        } catch _ {
            print("Unknown error")
        }
        */
        return shouldReconnect
    }
}