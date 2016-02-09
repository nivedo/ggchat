//
//  UserAPI.swift
//  ggchat
//
//  Created by Gary Chang on 12/15/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias HTTPJsonCompletion = (json: [String: AnyObject]?) -> Void
public typealias HTTPArrayCompletion = (array: [AnyObject]?) -> Void
typealias HTTPMessagesCompletion = (messages: [Message]?, xmls: [String]?) -> Void

protocol UserDelegate {
    
    func onAvatarUpdate(jid: String, success: Bool)
    func onRosterUpdate(success: Bool)
    func onChatsUpdate(success: Bool)
}

func ==(_ lhs: RosterUser, _ rhs: RosterUser) -> Bool {
    return lhs.jid == rhs.jid
}

class RosterUser: Hashable {
    var nickname: String
    var jid: String
    var avatar: String
    var avatarImage: UIImage?
    var isBuddy: Bool = false
    var isGroup: Bool = false
   
    var hashValue: Int {
        get {
            return jid.hashValue
        }
    }
   
    init(jid: String, groupName: String, avatar: String) {
        self.jid = UserAPI.stripResourceFromJID(jid)
        self.nickname = groupName
        self.avatar = avatar
        self.isGroup = true
    }
    
    init(profile: [String: AnyObject],
        avatarCompletion: ((Bool) -> Void)?) {
        self.jid = UserAPI.stripResourceFromJID(profile["jid"] as! String)
        self.nickname = profile["nickname"] as! String
        self.avatar = profile["avatar"] as! String
        self.isBuddy = profile["is_buddy"] as! Bool
        self.isGroup = profile["is_group"] as! Bool
            
        UserAPICoreData.sharedInstance.syncUser(self)
            
        self.initAvatar(avatarCompletion)
    }
   
    init(user: User, avatarCompletion: ((Bool) -> Void)?) {
        self.jid = UserAPI.stripResourceFromJID(user.jid!)
        self.nickname = user.nickname!
        self.avatar = user.avatar!
        if let isBuddy = user.is_buddy?.boolValue {
            self.isBuddy = isBuddy
        }
        if let isGroup = user.is_group?.boolValue {
            self.isGroup = isGroup
        }
        
        self.initAvatar(avatarCompletion)
    }
    
    func initAvatar(avatarCompletion: ((Bool) -> Void)?) {
        if self.avatar.length > 0 {
            S3ImageCache.sharedInstance.retrieveImageForKey(
                self.avatar,
                bucket: GGSetting.awsS3AvatarsBucketName,
                completion: { (image: UIImage?) -> Void in
                    self.avatarImage = image
                    avatarCompletion?(true)
                    UserAPI.sharedInstance.delegate?.onAvatarUpdate(self.jid, success: true)
            })
        } else {
            avatarCompletion?(false)
            UserAPI.sharedInstance.delegate?.onAvatarUpdate(self.jid, success: false)
        }
    }
    
    func isEqual(other: RosterUser?) -> Bool {
        if let otherUser = other {
            return self.jid == otherUser.jid
        } else {
            return false
        }
    }
    
    var displayName: String {
        get {
            if self.nickname.length > 0 {
                return self.nickname
            } else {
                return self.jid
            }
        }
    }

    var messageAvatarImage: MessageAvatarImage {
        get {
            if let image = self.avatarImage {
                return UserAPI.avatarFromImage(image)
            } else {
                return UserAPI.avatarFromInitials(self.displayName)
            }
        }
    }
}

class ChatConversation {
    var peerJID: String!
    var lastTime: NSDate!
    var lastMessage: Message!
    var unreadCount: Int = 0
    
    init(json: [String: AnyObject]) {
        if let timestamp = json["time"] as? NSTimeInterval,
            let jid = json["peer"] as? String,
            let xmlStr = json["xml"] as? String {
            self.peerJID = jid
            if let msg = Message.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: nil) {
                self.lastTime = msg.date
                self.lastMessage = msg
            } else {
                assert(false, "Unable to parse message xml \(xmlStr)")
            }
        }
    }
    
    init(jid: String, date: NSDate, xmlString: String) {
        self.peerJID = jid
        if let msg = Message.parseMessageFromString(xmlString, date: date, delegate: nil) {
            self.lastTime = date
            self.lastMessage = msg
        } else {
            assert(false, "Unable to parse message xml \(xmlString)")
        }
    }
    
    init(jid: String, date: NSDate, message: Message) {
        self.peerJID = jid
        self.lastTime = date
        self.lastMessage = message
    }
    
    func updateIfMoreRecent(date: NSDate, xmlString: String) -> Bool {
        if self.lastTime.compare(date) == NSComparisonResult.OrderedAscending {
            if let msg = Message.parseMessageFromString(xmlString, date: date, delegate: nil) {
                self.lastTime = date
                if msg.id != self.lastMessage.id {
                    self.lastMessage = msg
                    return true
                }
            }
        }
        return false
    }
    
    func updateIfMoreRecent(date: NSDate, message: Message) -> Bool {
        if self.lastTime.compare(date) == NSComparisonResult.OrderedAscending {
            self.lastTime = date
            if message.id != self.lastMessage.id {
                self.lastMessage = message
                return true
            }
        }
        return false
    }
   
    func incrementUnread() {
        self.unreadCount++
    }
    
    func resetUnread() {
        self.unreadCount = 0
    }
}

struct Language {
    static let English = "en"
    static let Japanese = "jp"
    static let ChineseTraditional = "tw"
    static let ChineseSimplified = "cn"
}

class UserSetting {
   
    var bracketOpen: String = "["
    var bracketClose: String = "]"
    var minAutocompleteCharacters: Int = 1
    var language: String! {
        didSet {
            if self.language == Language.English {
                self.minAutocompleteCharacters = 2
            } else {
                self.minAutocompleteCharacters = 1
            }
            self.updateBrackets(self.language)
        }
    }
    
    var sound: String = "on"
    var alert: String = "on"
    var keyboards = [String]()

    // Default settings
    init() {
        self.language = Language.English
        self.minAutocompleteCharacters = 2
        self.updateBrackets(self.language)
        
        self.keyboards = [ "hearthstone", "mtg" ]
    }
    
    func updateBrackets(language: String) {
        if language == Language.English {
            self.bracketOpen = "["
            self.bracketClose = "]"
        } else if language == Language.ChineseTraditional || language == Language.ChineseSimplified {
            self.bracketOpen = "［"  // "〈"
            self.bracketClose = "］" // "〉"
        } else if language == Language.Japanese {
            self.bracketOpen = "［"  // "〈"
            self.bracketClose = "］" // "〉"
        }
    }
    
}

class UserAPI {
    
    class var sharedInstance: UserAPI {
        struct Singleton {
            static let instance = UserAPI()
        }
        return Singleton.instance
    }
    
    var delegate: UserDelegate?

    class func avatarFromImage(image: UIImage) -> MessageAvatarImage {
        return MessageAvatarImageFactory.avatarImageWithImage(image, diameter: GGConfig.avatarSize)
    }
    
    class func avatarFromInitials(displayName: String) -> MessageAvatarImage {
        let tokens = displayName.tokens
        var initials = tokens[0].substringToIndex(tokens[0].startIndex.advancedBy(1))
        if tokens.count > 1 {
            let second = tokens[1]
            initials = "\(initials)\(second.substringToIndex(second.startIndex.advancedBy(1)))"
        }
        return MessageAvatarImageFactory.avatarImageWithUserInitials(
            initials,
            backgroundColor: UIColor(white: 0.85, alpha: 1.0),
            textColor: UIColor(white: 0.60, alpha: 1.0),
            font: UIFont.systemFontOfSize(14.0),
            diameter: GGConfig.avatarSize)
    }
    
    class func avatarFromText(text: String, diameter: CGFloat) -> MessageAvatarImage {
        return MessageAvatarImageFactory.avatarImageWithUserInitials(
            text,
            backgroundColor: UIColor(white: 0.85, alpha: 1.0),
            textColor: UIColor(white: 0.60, alpha: 1.0),
            font: UIFont.systemFontOfSize(12.0),
            diameter: diameter)
    }
    
    ////////////////////////////////////////////////////////////////////
    // Routes
    ////////////////////////////////////////////////////////////////////
    
    class func route(route: String) -> String {
        return "http://\(GGSetting.userApiHost):\(GGSetting.userApiPort)/\(route)"
    }
   
    class var registerUrl: String {
        return self.route("register")
    }
    
    class var creategroupUrl: String {
        return self.route("creategroup")
    }

    class var syncgroupsUrl: String {
        return self.route("syncgroups")
    }
   
    class var loginUrl: String {
        return self.route("login")
    }
    
    class var profileUrl: String {
        return self.route("profile")
    }
    
    class func updatedevicetokenUrl(ref: String) -> String {
        return self.route("updatedevicetoken?ref=\(ref)")
    }
    
    class var authUrl: String {
        return self.route("auth")
    }
    
    class func thirdpartyauthUrl(thirdparty: String) -> String {
        return self.route("thirdpartyauth?ref=\(thirdparty)")
    }
    
    class func thirdpartyloginUrl(thirdparty: String) -> String {
        return self.route("thirdpartylogin?ref=\(thirdparty)")
    }
    
    class func userinfoUrl(username: String) -> String {
        return "\(self.route("userinfo"))?username=\(username)"
    }
    
    class func addbuddyUrl(username: String) -> String {
        return "\(self.route("addbuddy?username=\(username)"))"
    }
    
    class func addbuddiesUrl(ref: String) -> String {
        return "\(self.route("addbuddies?ref=\(ref)"))"
    }

    class func deletebuddyUrl(jid: String) -> String {
        return "\(self.route("deletebuddy?jid=\(jid)"))"
    }

    class var rosterUrl: String {
        return "\(self.route("rosterv3"))"
    }

    /*
    class var chatsUrl: String {
        return "\(self.route("chats"))"
    }
    */

    class var syncUrl: String {
        return "\(self.route("sync"))"
    }
    
    class func historyUrl(peerJID: String, isGroup: Bool, limit: Int? = nil, end: NSDate? = nil) -> String {
        let tokens = peerJID.componentsSeparatedByString("@")
        let peerUUID = isGroup ? peerJID : tokens[0]
        let path = "history?peer=\(peerUUID)"
        var url = "\(self.route(path))"
        if let messageLimit = limit {
            url = "\(url)&limit=\(messageLimit)"
        }
        if let endDate = end {
            url = "\(url)&end=\(Int(endDate.timeIntervalSince1970 * 1e6))"
        }
        print(url)
        return url
    }
    
    class func deleteHistoryUrl(peerJID: String) -> String {
        let tokens = peerJID.componentsSeparatedByString("@")
        let peerUUID = tokens[0]
        let path = "deletehistory?peer=\(peerUUID)"
        let url = "\(self.route(path))"
        print(url)
        return url
    }
    
    ////////////////////////////////////////////////////////////////////
 
    func syncGroups(completion: ((Bool, String?) -> Void)?) {
        print("=================== sync groups ====================")
        if let token = self.authToken {
            self.post(UserAPI.syncgroupsUrl,
                authToken: token,
                jsonBody: nil,
                jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                    print(jsonDict)
            })
        }
    }
    
    func createGroup(groupName: String, avatar: String, users: Set<RosterUser>, completion: ((Bool, String?) -> Void)?) {
        if let token = self.authToken {
            var membersJID = users.map{ return UserAPI.stripResourceFromJID($0.jid) }
            membersJID.append(self.jidBareStr)
            self.post(UserAPI.creategroupUrl,
                authToken: token,
                jsonBody: [
                    "groupname": groupName,
                    "avatar": avatar,
                    "members": membersJID,
                    ],
                jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                    print(jsonDict)
                    if let json = jsonDict {
                        if let errorMsg = json["error"] as? String {
                            completion?(false, errorMsg)
                        } else if let roomJID = json["jid"] as? String {
                            print("Room \(roomJID) created \(json)")
                            completion?(true, roomJID)
                            // let roomJID = "\(NSUUID().UUIDString)@conference.blub.io"
                            let inviteesJID = users.map{ return UserAPI.stripResourceFromJID($0.jid) }
                            XMPPRoomManager.sharedInstance.joinOrCreateRoom(roomJID,
                                invitees: inviteesJID,
                                groupName: groupName,
                                avatar: avatar)
                        }
                    }
            })
        }
    }
    
    func register(username: String, email: String, password: String, completion: ((Bool, String?) -> Void)?) {
        self.post(UserAPI.registerUrl,
            authToken: nil,
            jsonBody: [
                "username": username,
                "email": email,
                "password": password ],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                if let json = jsonDict {
                    if let errorMsg = json["error"] as? String {
                        completion?(false, errorMsg)
                    } else if let newToken = json["token"] as? String,
                        let jid = json["jid"] as? String,
                        let pass = json["pass"] as? String
                    {
                        self.authToken = newToken
                        self.jid = jid
                        self.jpassword = pass
                        self.password = password
                        self.email = email
                        self.username = username
                        completion?(true, nil)
                    } else {
                        completion?(false, nil)
                    }
                } else {
                    completion?(false, nil)
                }
            })
    }
    
    func authenticateWithFacebook(facebookdId: String, facebookToken: String, completion: ((Bool, String?) -> Void)?) {
        self.post(UserAPI.thirdpartyauthUrl("facebook"),
            authToken: nil,
            jsonBody: [ "facebook_id": facebookdId, "facebook_token": facebookToken],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                // print(jsonDict)
                if let json = jsonDict {
                    if let errorMsg = json["error"] as? String {
                        completion?(false, errorMsg)
                    } else if let newToken = json["token"] as? String,
                        let jid = json["jid"] as? String,
                        let pass = json["pass"] as? String
                    {
                        self.authToken = newToken
                        self.jid = jid
                        self.jpassword = pass
                        
                        self.sync()
                        self.updatePushToken()
                        completion?(true, nil)
                    } else {
                        completion?(false, nil)
                    }
                } else {
                    completion?(false, nil)
                }
            }
        )
    }
    
    func loginWithFacebook(facebookUser: FacebookUser, completion: ((Bool, String?) -> Void)?) {
        print(facebookUser.userProfileJson)
        self.post(UserAPI.thirdpartyloginUrl("facebook"),
            authToken: nil,
            jsonBody: facebookUser.userProfileJson,
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                print(jsonDict)
                if let json = jsonDict {
                    if let errorMsg = json["error"] as? String {
                        completion?(false, errorMsg)
                    } else if let newToken = json["token"] as? String,
                        let jid = json["jid"] as? String,
                        let pass = json["pass"] as? String
                    {
                        self.authToken = newToken
                        self.jid = jid
                        self.jpassword = pass
                        
                        self.sync()
                        self.updatePushToken()
                        completion?(true, nil)
                    } else {
                        completion?(false, nil)
                    }
                } else {
                    completion?(false, nil)
                }
            }
        )
    }
    
    func login(email: String, password: String, completion: ((Bool, String?) -> Void)?) {
        if let prevEmail = self.emailFromUserDefaults {
            if prevEmail != email {
                self.logout()
            }
        }
        
        self.post(UserAPI.loginUrl,
            authToken: nil,
            jsonBody: [ "email": email, "password": password ],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                if let json = jsonDict {
                    if let errorMsg = json["error"] as? String {
                        completion?(false, errorMsg)
                    } else if let newToken = json["token"] as? String,
                        let jid = json["jid"] as? String,
                        let pass = json["pass"] as? String
                    {
                        self.authToken = newToken
                        print("------------------------------")
                        print(self.authToken)
                        print("------------------------------")
                        self.jid = jid
                        self.jpassword = pass
                        self.password = password
                        self.email = email
                        self.phoneNumber = json["phonenumber"] as? String
                        self.sync()
                        self.updatePushToken()
                        completion?(true, nil)
                    } else {
                        completion?(false, nil)
                    }
                } else {
                    completion?(false, nil)
                }
            })
    }
   
    func authenticate(completion: ((Bool, String?) -> Void)?) -> Bool {
        if self.authToken == nil {
            self.authToken = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.userApiAuthToken)
        }
        print("Authenticate with \(self.authToken)")
        if let token = self.authToken {
            self.get(UserAPI.authUrl,
                authToken: token,
                jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                    if let json = jsonDict {
                        if let errorMsg = json["error"] as? String {
                            completion?(false, errorMsg)
                        } else if let newToken = json["token"] as? String,
                            let jid = json["jid"] as? String,
                            let pass = json["pass"] as? String
                        {
                            self.hasAuth = true
                            self.authToken = newToken
                            self.jid = jid
                            self.jpassword = pass
                            // self.phoneNumber = json["phonenumber"] as? String
                           
                            self.sync()
                            self.updatePushToken()
                            completion?(true, nil)
                        } else {
                            completion?(true, nil)
                        }
                    } else {
                        completion?(false, nil)
                    }
            })
            return true
        }
        return false
    }
    
    func loadCoreData() {
        if let nickname = self.nicknameFromUserDefaults {
            self.nickname = nickname
        }
        if let avatarPath = self.avatarPathFromUserDefaults {
            self.avatarPath = avatarPath
            S3ImageCache.sharedInstance.retrieveImageForKey(
                avatarPath,
                bucket: GGSetting.awsS3AvatarsBucketName,
                completion: { (image: UIImage?) -> Void in
                    self.avatarImage = image
            })
        }
        self.loadRosterFromCoreData(nil)
        self.loadChatsFromCoreData()
    }
   
    func getUserinfo(username: String, jsonCompletion: HTTPJsonCompletion) {
        self.get(UserAPI.userinfoUrl(username),
            authToken: nil,
            jsonCompletion: jsonCompletion)
    }

    func getRoster(jid: String, arrayCompletion: HTTPArrayCompletion) {
        if let token = self.authToken {
            self.get(UserAPI.rosterUrl,
                authToken: token,
                arrayCompletion: arrayCompletion)
        }
    }
    
    func getProfile(jsonCompletion: HTTPJsonCompletion) -> Bool {
        if let token = self.authToken {
            self.get(UserAPI.profileUrl,
                authToken: token,
                jsonCompletion: jsonCompletion
            )
            return true
        }
        return false
    }
    
    func editProfile(jsonBody: [String: AnyObject], jsonCompletion: HTTPJsonCompletion?) -> Bool {
        if let token = self.authToken {
            self.post(UserAPI.profileUrl,
                authToken: token,
                jsonBody: jsonBody,
                jsonCompletion: jsonCompletion
            )
            return true
        }
        return false
    }
    
    func loadProfileFromJson(json: [String: AnyObject]) {
        print(json)
        if let nickname = json["nickname"] as? String {
            if nickname.length > 0 {
                self.nickname = nickname
            }
        }
        if let username = json["username"] as? String {
            if username.length > 0 {
                self.username = username
            }
        }
        if let language = json["lang"] as? String {
            if language.length > 0 {
                self.settings.language = language
            }
        }
        if let phoneNumber = json["phonenumber"] as? String {
            if phoneNumber.length > 0 {
                self.phoneNumber = phoneNumber
            }
        }
        if let sound = json["sound"] as? String {
            self.settings.sound = sound
        }
        if let alert = json["alert"] as? String {
            self.settings.alert = alert
        }
        if let avatarPath = json["avatar"] as? String {
            if avatarPath.length > 0 {
                // print("Downloading avatar at \(avatarPath)")
                self.avatarPath = avatarPath
                S3ImageCache.sharedInstance.retrieveImageForKey(
                    avatarPath,
                    bucket: GGSetting.awsS3AvatarsBucketName,
                    completion: { (image: UIImage?) -> Void in
                        self.avatarImage = image
                })
            }
        }
    }
    
    func loadProfilesFromJson(array: [AnyObject], completion: ((Bool) -> Void)? = nil) {
        print("loadProfilesFromJson --------------------------------->")
        print(array)
        // self.buddyList.removeAll()
        // self.rosterMap.removeAll()
        var buddyList = [RosterUser]()
        var rosterMap = [String: RosterUser]()
        for profile in array {
            let user = RosterUser(
                profile: profile as! [String: AnyObject],
                avatarCompletion: completion)
            if user.isBuddy {
                buddyList.append(user)
            }
            if user.isGroup {
                XMPPRoomManager.sharedInstance.joinRoom(user)
            }
            rosterMap[user.jid] = user
        }
        UserAPICoreData.sharedInstance.trimAllUsers(rosterMap)
        // XMPPMessageManager.sharedInstance.trimAllContacts(rosterMap)
        buddyList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
       
        dispatch_async(dispatch_get_main_queue()) {
            self.buddyList = buddyList
            self.rosterMap = rosterMap
            self.delegate?.onRosterUpdate(true)
        }
    }
    
    func loadRosterFromCoreData(completion: ((Bool) -> Void)? = nil) {
        print("loadRosterFromCoreData")
        
        if let users = UserAPICoreData.sharedInstance.fetchAllUsers() {
            print("Fetched \(users.count) roster user from core data")
            dispatch_async(dispatch_get_main_queue()) {
                self.buddyList.removeAll()
                self.rosterMap.removeAll()
                for user in users {
                    let rosterUser = RosterUser(user: user, avatarCompletion: completion)
                    if rosterUser.isBuddy {
                        self.buddyList.append(rosterUser)
                    }
                    if rosterUser.isGroup {
                        XMPPRoomManager.sharedInstance.joinRoom(rosterUser)
                    }
                    self.rosterMap[rosterUser.jid] = rosterUser
                }
                self.buddyList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
                self.delegate?.onRosterUpdate(true)
                completion?(true)
            }
        } else {
            self.delegate?.onRosterUpdate(false)
            completion?(false)
        }
    }
    
    func addRosterUser(user: RosterUser) {
        let jid = user.jid
        if self.rosterMap[jid] == nil {
            self.rosterMap[jid] = user
        }
    }
    
    func logout() {
        XMPPMessageManager.sharedInstance.clearCoreData()
        UserAPICoreData.sharedInstance.deleteAllUsers()
        FacebookManager.sharedInstance.loginManager.logOut()
        self.reset()
        let appDomain = NSBundle.mainBundle().bundleIdentifier
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
    }
    
    class func stripResourceFromJID(jid: String) -> String {
        let tokens = jid.componentsSeparatedByString("/")
        return tokens[0]
    }
    
    class func stripDomainFromJID(jid: String) -> String {
        let tokens = jid.componentsSeparatedByString("@")
        return tokens[0]
    }
    
    func isOutgoingJID(jid: String) -> Bool {
        return self.jidBareStr == UserAPI.stripResourceFromJID(jid)
    }
    
    func getHistory(peerJID: String, isGroup: Bool, limit: Int?, end: NSDate?, delegate: MessageMediaDelegate?, completion: HTTPMessagesCompletion? = nil) {
        // print("getHistory")
        if let token = self.authToken {
            self.get(UserAPI.historyUrl(peerJID, isGroup: isGroup, limit: limit, end: end),
                authToken: token,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        // print(array)
                        var messages = [Message]()
                        var xmls = [String]()
                        for element in array {
                            if let json = element as? [String: AnyObject] {
                                if let xmlStr = json["xml"] as? String, let timestamp = json["time"] as? NSTimeInterval {
                                    if let msg = Message.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: delegate) {
                                        messages.append(msg)
                                        xmls.append(xmlStr)
                                    }
                                }
                            }
                        }
                        completion?(messages: messages, xmls: xmls)
                    } else {
                        print("Failed to load history for \(peerJID)")
                        completion?(messages: nil, xmls: nil)
                    }
                })
        }
    }
    
    func deleteHistory(peerJID: String, completion: HTTPJsonCompletion? = nil) {
        if let token = self.authToken {
            self.post(UserAPI.deleteHistoryUrl(peerJID),
                authToken: token,
                jsonBody: nil,
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    completion?(json: jsonBody)
                }
            )
        }
    }
    
    func addBuddy(username: String, completion: HTTPJsonCompletion?) {
        if let token = self.authToken {
            self.post(UserAPI.addbuddyUrl(username),
                authToken: token,
                jsonBody: nil,
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    completion?(json: jsonBody)
                }
            )
        }
    }
    
    func addBuddiesFromAddressBook(contacts: [AnyObject], completion: HTTPJsonCompletion?) {
        if let token = self.authToken {
            self.post(UserAPI.addbuddiesUrl("addressbook"),
                authToken: token,
                jsonBody: [ "buddies" : contacts ],
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    completion?(json: jsonBody)
                }
            )
        }
    }
    
    func addBuddiesFromFacebook(friends: [[String:String]], facebookId: String, completion: HTTPJsonCompletion?) {
        if let token = self.authToken {
            self.post(UserAPI.addbuddiesUrl("facebook"),
                authToken: token,
                jsonBody: [ "friends" : friends, "facebookid" : facebookId ],
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    completion?(json: jsonBody)
                }
            )
        }
    }
    
    func deleteBuddy(jid: String, completion: HTTPJsonCompletion?) {
        if let token = self.authToken {
            self.post(UserAPI.deletebuddyUrl(jid),
                authToken: token,
                jsonBody: nil,
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    completion?(json: jsonBody)
                }
            )
        }
    }
    
    func removeBuddy(jid: String) -> [RosterUser] {
        for (index, user) in self.buddyList.enumerate() {
            if user.jid == jid {
                self.buddyList.removeAtIndex(index)
                break
            }
        }
        if let user = self.rosterMap[jid] {
            user.isBuddy = false
        }
        return self.buddyList
    }
    
    func removeChatConversation(jid: String) -> [ChatConversation] {
        for (index, chat) in self.chatsList.enumerate() {
            if chat.peerJID == jid {
                self.chatsList.removeAtIndex(index)
                break
            }
        }
        self.chatsMap.removeValueForKey(jid)
        return self.chatsList
    }
    
    func loadChatsFromCoreData() {
        dispatch_async(dispatch_get_main_queue()) {
            // self.chatsMap = XMPPMessageManager.sharedInstance.loadAllMostRecentArchivedMessages()
            self.chatsMap = XMPPMessageManager.sharedInstance.loadAllContacts()
            self.chatsList.removeAll()
            
            for (_,v) in self.chatsMap {
                // print("chat: \(k) --> \(v.lastMessage.displayText)")
                self.chatsList.append(v)
            }
            self.chatsList.sortInPlace({ $0.lastTime.compare($1.lastTime) == NSComparisonResult.OrderedDescending})
            self.delegate?.onChatsUpdate(true)
            
            print("Loaded \(self.chatsList.count) from core data")
        }
    }
    
    func loadMessagesFromJson(messagesArray: [AnyObject]) {
        // print(messagesArray)
        dispatch_async(dispatch_get_main_queue()) {
            var sort = false
            for element in messagesArray {
                if let json = element as? [String: AnyObject] {
                    let chat = ChatConversation(json: json)
                    var update = false
                    if let existingChat = self.chatsMap[chat.peerJID] {
                        update = existingChat.updateIfMoreRecent(chat.lastMessage.date, message: chat.lastMessage)
                    } else {
                        self.chatsList.append(chat)
                        self.chatsMap[chat.peerJID] = chat
                        update = true
                    }
                    if update {
                        sort = true
                        if let xml = json["xml"] as? String {
                            XMPPMessageManager.sharedInstance.archiveMostRecentMessage(chat, xmlString: xml)
                        }
                    }
                }
            }
            if sort {
                print("[SYNC] Updating most recent messages.")
                self.chatsList.sortInPlace({ $0.lastTime.compare($1.lastTime) == NSComparisonResult.OrderedDescending})
                self.delegate?.onChatsUpdate(true)
            }
        }
    }
    
    func sync(completion: ((Bool) -> Void)? = nil) {
        print("=================== sync ====================")
        if let token = self.authToken {
            self.get(UserAPI.syncUrl,
                authToken: token,
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    if let json = jsonBody {
                        if let profileJson = json["profile"] as? [String: AnyObject] {
                            self.loadProfileFromJson(profileJson)
                        }
                        if let profilesArray = json["profiles"] as? [AnyObject] {
                            self.loadProfilesFromJson(profilesArray)
                        }
                        if let messagesArray = json["messages"] as? [AnyObject] {
                            self.loadMessagesFromJson(messagesArray)
                        }
                        completion?(true)
                    } else {
                        self.delegate?.onChatsUpdate(false)
                        completion?(false)
                    }
                    // print("chat list count: \(self.chatsList.count)")
            })
        }
    }
    
    func newMessage(peerJID: String, date: NSDate, message: Message) -> ChatConversation {
        let jid = UserAPI.stripResourceFromJID(peerJID)
        if let chat = self.chatsMap[jid] {
            chat.updateIfMoreRecent(date, message: message)
            self.chatsList.sortInPlace({ $0.lastTime.compare($1.lastTime) == NSComparisonResult.OrderedDescending})
            return chat
        } else {
            let chat = ChatConversation(jid: jid, date: date, message: message)
            self.chatsMap[jid] = chat
            self.chatsList.append(chat)
            self.chatsList.sortInPlace({ $0.lastTime.compare($1.lastTime) == NSComparisonResult.OrderedDescending})
            
            // New chat or user, sync
            // self.sync()
            return chat
        }
    }
    
    func readAllMessages(peerJID: String) {
        let jid = UserAPI.stripResourceFromJID(peerJID)
        if let chat = self.chatsMap[jid] {
            chat.unreadCount = 0
        }
    }
    
    var totalUnreadCount: Int {
        get {
            var totalUnread = 0
            for (_, chat) in UserAPI.sharedInstance.chatsMap {
                totalUnread += chat.unreadCount
            }
            return totalUnread
        }
    }
    
    func updatePushToken() {
        if let token = self.authToken, let pushToken = self.pushToken {
            /*
            let success = self.editProfile(["pushToken": pushToken] , jsonCompletion: { HTTPJsonCompletion in
                print("Successfully pushed token for \(self.displayName)")
            })
            */
            self.post(UserAPI.updatedevicetokenUrl("apple"),
                authToken: token,
                jsonBody: [ "pushToken" : pushToken ],
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    if let json = jsonBody {
                        if let errorMsg = json["error"] as? String {
                            print("Unable to push token for \(self.displayName), reason: \(errorMsg)")
                        }
                    }
            })
        }
    }
    
    func updateAvatarImage(image: UIImage, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        let uniquePath = "\(NSProcessInfo.processInfo().globallyUniqueString).jpg"
        return self.editProfile(["avatar": uniquePath], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                // print(json)
                AWSS3UploadManager.sharedInstance.upload(image,
                    fileName: uniquePath,
                    userData: nil,
                    bucket: GGSetting.awsS3AvatarsBucketName,
                    completion: { (success: Bool) -> Void in
                        self.avatarPath = uniquePath
                        self.avatarImage = image
                        jsonCompletion?(json: jsonBody)
                })
            }
        })
    }
    
    func updateNickname(nickname: String, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        return self.editProfile(["nickname": nickname], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.nickname = nickname
            }
            jsonCompletion?(json: jsonBody)
        })
    }
    
    func updateLanguage(language: String, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        return self.editProfile(["lang": language], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.settings.language = language
            }
            jsonCompletion?(json: jsonBody)
        })
    }
    
    func updateSound(sound: String, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        return self.editProfile(["sound": sound], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.settings.sound = sound
            }
            jsonCompletion?(json: jsonBody)
        })
    }
    
    func updateAlert(alert: String, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        return self.editProfile(["alert": alert], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.settings.alert = alert
            }
            jsonCompletion?(json: jsonBody)
        })
    }
    
    func updatePhoneNumber(phoneNumber: String, jsonCompletion: HTTPJsonCompletion?) -> Bool {
        return self.editProfile(["phonenumber": phoneNumber], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.phoneNumber = phoneNumber
            }
            jsonCompletion?(json: jsonBody)
        })
    }
    
    func getAvatarImage(jid: String) -> MessageAvatarImage {
        if let user = self.rosterMap[jid] {
            if user.jid == jid {
                return user.messageAvatarImage
            }
        }
        return UserAPI.avatarFromInitials(jid)
    }
    
    func getDisplayName(jid: String) -> String {
        if let user = self.rosterMap[jid] {
            if user.jid == jid {
                return user.displayName
            }
        }
        return jid
    }
    
    ////////////////////////////////////////////////////////////////////
   
    var hasAuth: Bool = false
    
    var canAuth: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(GGKey.userApiAuthToken) != nil
        }
    }
    var canAuthWithFacebook: Bool {
        get {
            return FBSDKAccessToken.currentAccessToken() != nil
            // return NSUserDefaults.standardUserDefaults().stringForKey(GGKey.facebookToken) != nil
        }
    }
    
    var sameUserAuth: Bool {
        get {
            return self.canAuth || self.canAuthWithFacebook
        }
    }
    
    var authToken: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.authToken, forKey: GGKey.userApiAuthToken)
        }
    }
    
    var pushToken: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.pushToken, forKey: GGKey.userApiPushToken)
        }
    }
    
    var jid: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.jid, forKey: GGKey.userApiJID)
        }
    }
   
    var hasJID: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.userApiJID) != nil
        }
    }
    
    var jidStr: String {
        get {
            if let jid = self.jid {
                return jid
            } else {
                return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.userApiJID) as! String
            }
        }
    }
    
    var jidBareStr: String {
        get {
            return UserAPI.stripResourceFromJID(self.jidStr)
        }
    }
    
    var uuidStr: String {
        get {
            return UserAPI.stripDomainFromJID(self.jidBareStr)
        }
    }
    
    var jpassword: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.jpassword, forKey: GGKey.userApiJabberdPassword)
        }
    }
    
    var jpasswordBareStr: String {
        get {
            if let jpassword = self.jpassword {
                return jpassword
            } else {
                return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.userApiJabberdPassword) as! String
            }
        }
    }
   
    var username: String?
    var phoneNumber: String?
    
    var email: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(email, forKey: GGKey.email)
        }
    }
    var emailFromUserDefaults: String? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.email) as? String
        }
    }
    
    var password: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.password, forKey: GGKey.password)
        }
    }
    var passwordFromUserDefaults: String? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.password) as? String
        }
    }
    
    var nickname: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.nickname, forKey: GGKey.userApiNickname)
        }
    }
    var nicknameFromUserDefaults: String? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.userApiNickname) as? String
        }
    }
    
    var avatarPath: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.nickname, forKey: GGKey.userApiAvatarPath)
        }
    }
    var avatarPathFromUserDefaults: String? {
        get {
            return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.userApiAvatarPath) as? String
        }
    }
    
    private var facebookId_: String?
    var facebookId: String? {
        get {
            if let id = self.facebookId {
                return id
            } else {
                return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.facebookId) as? String
            }
        }
        set (id) {
            self.facebookId = id
            NSUserDefaults.standardUserDefaults().setValue(id, forKey: GGKey.facebookId)
        }
    }
    
    private var facebookToken_: String?
    var facebookToken: String? {
        get {
            if let token = self.facebookToken {
                return token
            } else {
                return NSUserDefaults.standardUserDefaults().valueForKey(GGKey.facebookToken) as? String
            }
        }
        set (token) {
            self.facebookToken = token
            NSUserDefaults.standardUserDefaults().setValue(token, forKey: GGKey.facebookToken)
        }
    }
    
    var avatarImage: UIImage?
    var buddyList: [RosterUser] = [RosterUser]()
    var rosterMap: [String: RosterUser] = [String: RosterUser]()
    var chatsList: [ChatConversation] = [ChatConversation]()
    var chatsMap: [String: ChatConversation] = [String: ChatConversation]()
    var settings: UserSetting = UserSetting()
    
    func reset() {
        self.username = nil
        self.email = nil
        self.phoneNumber = nil
        self.password = nil
        self.nickname = nil
        self.avatarPath = nil
        self.avatarImage = nil
        self.jid = nil
        self.jpassword = nil
        self.authToken = nil
        self.pushToken = nil
        self.hasAuth = false
        
        self.chatsMap.removeAll()
        self.chatsList.removeAll()
        self.buddyList.removeAll()
        self.rosterMap.removeAll()
        self.settings = UserSetting()
    }
    
    var displayName: String {
        get {
            if let nickname = self.nickname {
                return nickname
            } else if let username = self.username {
                return username
            } else if let email = self.email {
                return email
            } else {
                return self.jidBareStr
            }
        }
    }
    
    var avatar: MessageAvatarImage {
        get {
            if let image = self.avatarImage {
                return UserAPI.avatarFromImage(image)
            } else {
                return UserAPI.avatarFromInitials(self.displayName)
            }
        }
    }
    
    private func post(urlPath: String, authToken: String?, jsonBody: [String: AnyObject]?, jsonCompletion: HTTPJsonCompletion?) {
        let URL: NSURL = NSURL(string: urlPath)!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "POST"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let json = jsonBody {
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(json,
                    options: NSJSONWritingOptions.PrettyPrinted)
                request.HTTPBody = jsonData
            } catch {
                print("Unable to parse json \(jsonBody)")
                return
            }
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil && data != nil else { // check for fundamental networking error
                print("Error=\(error)")
                jsonCompletion?(json: nil)
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 { // check for http errors
                print("StatusCode should be 200, but is \(httpStatus.statusCode)")
                print("Response = \(response)")
            }
            if let jsonData = data {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        jsonData,
                        options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] {
                        jsonCompletion?(json: response)
                    } else {
                        jsonCompletion?(json: nil)
                    }
                } catch {
                    jsonCompletion?(json: nil)
                }
            }
        }
        task.resume()
    }
    
    private func get(urlPath: String, authToken: String?, jsonCompletion: HTTPJsonCompletion?) {
        let URL: NSURL = NSURL(string: urlPath)!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil && data != nil else { // check for fundamental networking error
                print("Error=\(error)")
                jsonCompletion?(json: nil)
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 { // check for http errors
                print("StatusCode should be 200, but is \(httpStatus.statusCode)")
                print("Response = \(response)")
                // jsonCompletion?(json: nil)
            }
            if let jsonData = data {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        jsonData,
                        options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] {
                        jsonCompletion?(json: response)
                    } else {
                        jsonCompletion?(json: nil)
                    }
                } catch {
                    jsonCompletion?(json: nil)
                }
            }
        }
        task.resume()
    }
    
    private func get(urlPath: String, authToken: String?, arrayCompletion: HTTPArrayCompletion?) {
        let URL: NSURL = NSURL(string: urlPath)!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil && data != nil else { // check for fundamental networking error
                print("Error=\(error)")
                arrayCompletion?(array: nil)
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 { // check for http errors
                print("StatusCode should be 200, but is \(httpStatus.statusCode)")
                print("Response = \(response)")
                // arrayCompletion?(array: nil)
            }
            if let arrayData = data {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        arrayData,
                        options: NSJSONReadingOptions.AllowFragments) as? [AnyObject] {
                        arrayCompletion?(array: response)
                    } else {
                        arrayCompletion?(array: nil)
                    }
                } catch {
                    arrayCompletion?(array: nil)
                }
            }
        }
        task.resume()
    } 
}