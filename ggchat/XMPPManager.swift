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
    var displayName: String?
    var stream: XMPPStream!
    var roster: XMPPRoster!
    var rosterStorage: XMPPRosterCoreDataStorage = XMPPRosterCoreDataStorage()
    // var rosterStorage: XMPPRosterMemoryStorage = XMPPRosterMemoryStorage()
    var reconnecter: XMPPReconnect!
    var deliveryReceipts: XMPPMessageDeliveryReceipts!
    var capabilities: XMPPCapabilities!
    var capabilitiesStorage: XMPPCapabilitiesCoreDataStorage!
    var vCardStorage: XMPPvCardCoreDataStorage!
    var vCardTempModule: XMPPvCardTempModule!
    var vCardAvatarModule: XMPPvCardAvatarModule!
    
    // Delegates and completion handlers
    var delegate: XMPPManagerDelegate?
    var connectCompletionHandler: StreamCompletionHandler?
    var authenticateCompletionHandler: StreamCompletionHandler?
   
    //////////////////////////////////////////////////////////////////////////////
    // Class helper methods
    //////////////////////////////////////////////////////////////////////////////
  
    class func avatarImageForJID(jid: String) -> (UIImage?, UIImage?) {
        let avatarImageDataSource = GGModelData.sharedInstance.getAvatar(jid)
        
        let avatarImage: UIImage? = avatarImageDataSource.avatarImage
        if (avatarImage == nil) {
            return (avatarImageDataSource.avatarPlaceholderImage, nil)
        } else {
            return (avatarImage!, avatarImageDataSource.avatarHighlightedImage)
        }
    }
    
    var jid: String {
        get {
            if (self.isConnected()) {
                return self.stream.myJID.bare()
            } else {
                if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.jid) {
                    return previousJID
                } else {
                    return GGKey.jid
                }
            }
        }
    }
   
    func displayName(force: Bool) -> String {
        if force || self.displayName == nil {
            if (self.isConnected()) {
                // TODO
                return self.stream.myJID.bare()
            } else {
                if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.displayName) {
                    return previousJID
                } else {
                    return GGKey.displayName
                }
            }
        }
        return self.displayName!
    }
    
    func updateDisplayName(givenName: String, familyName: String) {
        // let vCardTemp: XMPPvCardTemp = self.vCardTempModule.myvCardTemp
        let vCardXML = DDXMLElement(name: "vCard", xmlns: "vcard-temp")
        let newvCardTemp: XMPPvCardTemp = XMPPvCardTemp(fromElement: vCardXML)
        newvCardTemp.givenName = givenName
        newvCardTemp.familyName = familyName
        self.vCardTempModule.updateMyvCardTemp(newvCardTemp)
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
        
        XMPPRosterManager.sharedInstance.fetchedResultsController()?.delegate = XMPPRosterManager.sharedInstance
    }
    
    class func stop() {
        sharedInstance.teardown()
    }
    
    func setup() {
        self.stream = XMPPStream()
        
        #if !TARGET_IPHONE_SIMULATOR
            self.stream.enableBackgroundingOnSocket = true
        #endif
        
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
        
        // Initialize vCard support
        self.vCardStorage = XMPPvCardCoreDataStorage.sharedInstance()
        self.vCardTempModule = XMPPvCardTempModule(withvCardStorage: self.vCardStorage)
        self.vCardAvatarModule = XMPPvCardAvatarModule(withvCardTempModule: self.vCardTempModule)
        self.vCardTempModule.activate(self.stream)
        self.vCardAvatarModule.activate(self.stream)
    }
    
    func teardown() {
        self.stream.removeDelegate(self)
        self.roster.removeDelegate(self)
        
        self.reconnecter.deactivate()
        self.roster.deactivate()
        self.capabilities.deactivate()
        self.vCardTempModule.deactivate()
        self.vCardAvatarModule.deactivate()

        self.stream.disconnect()
    }

    //////////////////////////////////////////////////////////////////////////////

    
    func isConnected() -> Bool {
        return self.stream.isConnected()
    }
    
    func connect(
        username usernameOrNil: String?,
        password passwordOrNil: String?,
        connectCompletionHandler: StreamCompletionHandler?,
        authenticateCompletionHandler: StreamCompletionHandler?) {
            
        self.connectCompletionHandler = connectCompletionHandler
        self.authenticateCompletionHandler = authenticateCompletionHandler
            
        if (self.stream.isConnected()) {
            // Already connected
            if (self.stream.isAuthenticated()) {
                print("Error: Already logged in. Please logout before attempting another login.")
            } else {
                self.xmppStreamDidConnect(self.stream)
            }
            return
        }
     
        // Set username
        if (usernameOrNil == nil) {
            if let previousUsername = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.username) {
                self.username = previousUsername
            } else {
                print("Error: Please enter username before trying to connect.")
                return
            }
        } else {
            self.username = usernameOrNil!
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
       
        self.stream.myJID = XMPPJID.jidWithUser(
            self.username,
            domain: GGSetting.xmppDomain,
            resource: "ios")
        
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
      
        // Save usernmae
        NSUserDefaults.standardUserDefaults().setValue(self.username, forKey: GGKey.username)
        NSUserDefaults.standardUserDefaults().setValue(self.password, forKey: GGKey.password)
        
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