//
//  XMPPManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/26/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias StreamCompletionHandler = (stream: XMPPStream, error: String?) -> Void

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
    // XMPPvCardTempModuleDelegate {

    var username: String!
    var password: String!
    var jid_: String?
    var domain: String = GGSetting.xmppDomain
    var stream: XMPPStream!
    var roster: XMPPRoster!
    var rosterStorage: XMPPRosterCoreDataStorage = XMPPRosterCoreDataStorage()
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
 
    /*
    class func avatarForJID(jid: String) -> MessageAvatarImage {
        var avatar: MessageAvatarImage?
       
        var xmppUser: XMPPUserCoreDataStorageObject?
        if let user = sharedInstance.rosterStorage.userForJID(
            XMPPJID.jidWithString(jid),
            xmppStream: sharedInstance.stream,
            managedObjectContext: XMPPRosterManager.sharedInstance.managedObjectContext_roster()) {
            xmppUser = user
            if let photo = user.photo {
                avatar = MessageAvatarImageFactory.avatarImageWithImage(photo, diameter: GGConfig.avatarSize)
                return avatar!
            }
        }
        
        if let photoData = sharedInstance.vCardAvatarModule?.photoDataForJID(XMPPJID.jidWithString(jid)) {
            let photo = UIImage(data: photoData)!
            avatar = MessageAvatarImageFactory.avatarImageWithImage(photo, diameter: GGConfig.avatarSize)
            if xmppUser != nil {
                xmppUser!.photo = photo
            }
        } else {
            print("Unable to find avatar for \(jid) on ejabberd server")
            avatar = GGModelData.sharedInstance.getAvatar(jid)
            if xmppUser != nil {
                xmppUser!.photo = avatar!.avatarImage
            }
        }
        
        return avatar!
    }
    
    class func avatarImageForJID(jid: String) -> (UIImage?, UIImage?) {
        let avatar = self.avatarForJID(jid)
        let avatarImage: UIImage? = avatar.avatarImage
        if (avatarImage == nil) {
            return (avatar.avatarPlaceholderImage, nil)
        } else {
            return (avatarImage!, avatar.avatarHighlightedImage)
        }
    }
    */
    
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
  
    /*
    var displayName: String {
        let vCard = self.vCardStorage.vCardTempForJID(
            self.stream.myJID,
            xmppStream: self.stream)
        if let displayName = vCard?.nickname {
            if displayName != "" {
                NSUserDefaults.standardUserDefaults().setValue(displayName, forKey: GGKey.displayName)
                return displayName
            }
        }
       
        if let email = UserAPI.sharedInstance.email {
            return email
        } else {
            if let previousJID = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.displayName) {
                return previousJID
            } else {
                return self.stream.myJID.bare()
            }
        }
    }
    */
   
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
        self.roster.removeDelegate(self)
        // self.vCardTempModule.removeDelegate(self)
        // self.lastActivity.removeDelegate(self)
        
        self.reconnecter.deactivate()
        self.roster.deactivate()
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
    
    func connectWithJID(
        jid jidOrNil: String?,
        password passwordOrNil: String?,
        connectCompletionHandler: StreamCompletionHandler?,
        authenticateCompletionHandler: StreamCompletionHandler?) {
            
        self.connectCompletionHandler = connectCompletionHandler
        self.authenticateCompletionHandler = authenticateCompletionHandler
            
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
   
    /*
    func connect(
        username usernameOrNil: String?,
        password passwordOrNil: String?,
        connectCompletionHandler: StreamCompletionHandler?,
        authenticateCompletionHandler: StreamCompletionHandler?) {
            
        self.connectCompletionHandler = connectCompletionHandler
        self.authenticateCompletionHandler = authenticateCompletionHandler
            
        if (self.stream.isConnected()) {
            // Already connected
            if !self.stream.isAuthenticated() {
                self.xmppStreamDidConnect(self.stream)
            } else {
                self.xmppStreamDidAuthenticate(self.stream)
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
            domain: self.domain,
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
    */
   
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
        let errMsg = "didNotAuthenticate: " + error.stringValue()
        print(errMsg)
        self.authenticateCompletionHandler?(stream: sender, error: "Username or password incorrect")
    }

    //////////////////////////////////////////////////////////////////////////////
    // XMPPManager public interface
    //////////////////////////////////////////////////////////////////////////////
    
    func sendSubscriptionRequestForRoster(jidStr: String) {
        let jid = XMPPJID.jidWithString(jidStr)
        self.roster.addUser(jid, withNickname: nil)
    }
}