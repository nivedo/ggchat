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

class RosterUser {
    var nickname: String
    var jid: String
    var jidBare: String
    var avatar: String
    var avatarImage: UIImage?
    
    init(profile: [String: AnyObject],
        avatarCompletion: ((Bool) -> Void)?) {
        self.jid = profile["jid"] as! String
        self.jidBare = UserAPI.stripResourceFromJID(self.jid)
        self.nickname = profile["nickname"] as! String
        self.avatar = profile["avatar"] as! String
            
        UserAPICoreData.sharedInstance.syncUser(self)
            
        self.initAvatar(avatarCompletion)
    }
    
    init(user: User, avatarCompletion: ((Bool) -> Void)?) {
        self.jid = user.jid!
        self.jidBare = UserAPI.stripResourceFromJID(self.jid)
        self.nickname = user.nickname!
        self.avatar = user.avatar!
        
        self.initAvatar(avatarCompletion)
    }
    
    func initAvatar(avatarCompletion: ((Bool) -> Void)?) {
        if self.avatar.length > 0 {
            print("Downloading avatar at \(self.avatar)")
            
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
            return self.jidBare == otherUser.jidBare
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
            if let msg = UserAPI.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: nil) {
                self.lastTime = msg.date
                self.lastMessage = msg
            } else {
                assert(false, "Unable to parse message xml \(xmlStr)")
            }
        }
    }
    
    init(jid: String, date: NSDate, xmlString: String) {
        self.peerJID = jid
        if let msg = UserAPI.parseMessageFromString(xmlString, date: date, delegate: nil) {
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
    
    func updateIfMoreRecent(date: NSDate, xmlString: String) {
        if self.lastTime.compare(date) == NSComparisonResult.OrderedAscending {
            if let msg = UserAPI.parseMessageFromString(xmlString, date: date, delegate: nil) {
                self.lastTime = date
                self.lastMessage = msg
            }
        }
    }
    
    func updateIfMoreRecent(date: NSDate, message: Message) {
        if self.lastTime.compare(date) == NSComparisonResult.OrderedAscending {
            self.lastTime = date
            self.lastMessage = message
        }
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

    // Default settings
    init() {
        self.language = Language.English
        self.minAutocompleteCharacters = 2
        self.updateBrackets(self.language)
        /*
        self.language = Language.ChineseTraditional
        self.minAutocompleteCharacters = 1
        */
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
    
    ////////////////////////////////////////////////////////////////////
    // Routes
    ////////////////////////////////////////////////////////////////////
    
    class func route(route: String) -> String {
        return "http://\(GGSetting.userApiHost):\(GGSetting.userApiPort)/\(route)"
    }
   
    class var registerUrl: String {
        return self.route("register")
    }
   
    class var loginUrl: String {
        return self.route("login")
    }
    
    class var profileUrl: String {
        return self.route("profile")
    }
    
    class var authUrl: String {
        return self.route("auth")
    }
    
    class func userinfoUrl(username: String) -> String {
        return "\(self.route("userinfo"))?username=\(username)"
    }
    
    class func addbuddyUrl(username: String) -> String {
        return "\(self.route("addbuddy?username=\(username)"))"
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
    
    class func historyUrl(peerJID: String, limit: Int? = nil, end: NSDate? = nil) -> String {
        let tokens = peerJID.componentsSeparatedByString("@")
        let peerUUID = tokens[0]
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
    
    ////////////////////////////////////////////////////////////////////
    
    func register(username: String, email: String, password: String, completion: ((Bool) -> Void)?) {
        self.post(UserAPI.registerUrl,
            authToken: nil,
            jsonBody: [
                "username": username,
                "email": email,
                "password": password ],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                if let json = jsonDict,
                let newToken = json["token"] as? String,
                let jid = json["jid"] as? String,
                let pass = json["pass"] as? String
                {
                    self.authToken = newToken
                    self.jid = jid
                    self.jpassword = pass
                    self.password = password
                    self.email = email
                    self.username = username
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
    }
    
    func login(email: String, password: String, completion: ((Bool) -> Void)?) {
        self.post(UserAPI.loginUrl,
            authToken: nil,
            jsonBody: [ "email": email, "password": password ],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                if let json = jsonDict,
                let newToken = json["token"] as? String,
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
                    self.sync()
                    self.updatePushToken()
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
    }
   
    func authenticate(completion: ((Bool) -> Void)?) -> Bool {
        if self.authToken == nil {
            self.authToken = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.userApiAuthToken)
        }
        print("Authenticate with \(self.authToken)")
        if let token = self.authToken {
            self.get(UserAPI.authUrl,
                authToken: token,
                jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                    if let json = jsonDict,
                    let newToken = json["token"] as? String,
                    let jid = json["jid"] as? String,
                    let pass = json["pass"] as? String
                    {
                        self.authToken = newToken
                        self.jid = jid
                        self.jpassword = pass
                       
                        // self.loadRosterFromCoreData(nil)
                        // self.loadChatsFromCoreData()
                        
                        self.sync()
                        self.updatePushToken()
                        completion?(true)
                    } else {
                        completion?(false)
                    }
            })
            return true
        }
        return false
    }
    
    func loadCoreData() {
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
        if let avatarPath = json["avatar"] as? String {
            if avatarPath.length > 0 {
                print("Downloading avatar at \(avatarPath)")
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
        self.rosterList.removeAll()
        self.rosterMap.removeAll()
        for profile in array {
            let user = RosterUser(
                profile: profile as! [String: AnyObject],
                avatarCompletion: completion)
            self.rosterList.append(user)
            self.rosterMap[user.jid] = user
        }
        UserAPICoreData.sharedInstance.trimAllUsers(self.rosterMap)
        self.rosterList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
    }
    
    func loadRosterFromCoreData(completion: ((Bool) -> Void)? = nil) {
        print("loadRosterFromCoreData")
        
        if let users = UserAPICoreData.sharedInstance.fetchAllUsers() {
            print("Fetched \(users.count) roster user from core data")
            dispatch_async(dispatch_get_main_queue()) {
                self.rosterList.removeAll()
                self.rosterMap.removeAll()
                for user in users {
                    let rosterUser = RosterUser(user: user, avatarCompletion: completion)
                    self.rosterList.append(rosterUser)
                    self.rosterMap[rosterUser.jid] = rosterUser
                }
                self.rosterList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
                self.delegate?.onRosterUpdate(true)
                completion?(true)
            }
        } else {
            self.delegate?.onRosterUpdate(false)
            completion?(false)
        }
    }
    
    func cacheRoster(completion: ((Bool) -> Void)? = nil) {
        if let jid = self.jid {
            UserAPI.sharedInstance.getRoster(jid,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.rosterList.removeAll()
                            self.rosterMap.removeAll()
                            for profile in array {
                                let user = RosterUser(
                                    profile: profile as! [String: AnyObject],
                                    avatarCompletion: completion)
                                self.rosterList.append(user)
                                self.rosterMap[user.jid] = user
                            }
                            UserAPICoreData.sharedInstance.trimAllUsers(self.rosterMap)
                            self.rosterList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
                            completion?(true)
                            self.delegate?.onRosterUpdate(true)
                        }
                    } else {
                        completion?(false)
                        self.delegate?.onRosterUpdate(false)
                    }
                }
            )
        }
        completion?(false)
        self.delegate?.onRosterUpdate(false)
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
    
    class func parseMessageFromElement(element: DDXMLElement?, date: NSDate, delegate: MessageMediaDelegate?) -> Message? {
        if let bodyElement = element?.elementForName("body"),
            let from = element?.attributeStringValueForName("from"),
            let type = element?.attributeStringValueForName("type") {
            if type != "chat" {
                return nil
            }
                
            let id = element?.attributeStringValueForName("id")
            
            let body = bodyElement.stringValue()
            let fromBare = UserAPI.stripResourceFromJID(from)
            
            if let _ = bodyElement.elementForName("photo") {
                let photo = bodyElement.elementForName("photo")!
                let originalKey = photo.elementForName("originalKey")!.stringValue()
                let thumbnailKey = photo.elementForName("thumbnailKey")!.stringValue()
            
                let photoMedia = PhotoMediaItem(thumbnailKey: thumbnailKey, originalKey: originalKey, delegate: delegate)
                let photoMessage = Message(
                    senderId: fromBare,
                    senderDisplayName: UserAPI.sharedInstance.getDisplayName(fromBare),
                    isOutgoing: UserAPI.sharedInstance.isOutgoingJID(fromBare),
                    date: date,
                    media: photoMedia)
                photoMessage.id = id
                return photoMessage
            } else {
                // print("\(UserAPI.sharedInstance.rosterMap[fromBare]?.displayName) \(body)")
                if let asset = AssetManager.getSingleEncodedAsset(body) {
                    let wikiMedia: WikiMediaItem = WikiMediaItem(imageURL: asset.url, delegate: delegate)
                    let message = Message(
                        senderId: fromBare,
                        senderDisplayName: UserAPI.sharedInstance.getDisplayName(fromBare),
                        isOutgoing: UserAPI.sharedInstance.isOutgoingJID(fromBare),
                        date: date,
                        media: wikiMedia,
                        text: body)
                    message.id = id
                    return message
                }
                let fullMessage = Message(
                    senderId: fromBare,
                    senderDisplayName: UserAPI.sharedInstance.getDisplayName(fromBare),
                    isOutgoing: UserAPI.sharedInstance.isOutgoingJID(fromBare),
                    date: date,
                    text: body)
                fullMessage.id = id
                return fullMessage
            }
        }
        return nil
    }
   
    class func stripResourceFromJID(jid: String) -> String {
        let tokens = jid.componentsSeparatedByString("/")
        return tokens[0]
    }
    
    func isOutgoingJID(jid: String) -> Bool {
        return self.jidBareStr == UserAPI.stripResourceFromJID(jid)
    }
    
    func getHistory(peerJID: String, limit: Int?, end: NSDate?, delegate: MessageMediaDelegate?, completion: HTTPMessagesCompletion? = nil) {
        // print("getHistory")
        if let token = self.authToken {
            self.get(UserAPI.historyUrl(peerJID, limit: limit, end: end),
                authToken: token,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        // print(array)
                        var messages = [Message]()
                        var xmls = [String]()
                        for element in array {
                            if let json = element as? [String: AnyObject] {
                                if let xmlStr = json["xml"] as? String, let timestamp = json["time"] as? NSTimeInterval {
                                    if let msg = UserAPI.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: delegate) {
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
    
    func loadChatsFromCoreData() {
        dispatch_async(dispatch_get_main_queue()) {
            self.chatsMap = XMPPMessageManager.sharedInstance.loadAllMostRecentArchivedMessages()
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
        dispatch_async(dispatch_get_main_queue()) {
            self.chatsList.removeAll()
            self.chatsMap.removeAll()
            for element in messagesArray {
                if let json = element as? [String: AnyObject] {
                    // print(json)
                    let chat = ChatConversation(json: json)
                    self.chatsList.append(chat)
                    self.chatsMap[chat.peerJID] = chat
                }
            }
            self.delegate?.onChatsUpdate(true)
        }
    }
    
    func sync() {
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
                    } else {
                        self.delegate?.onChatsUpdate(false)
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
            self.sync()
            return chat
        }
    }
    
    func readAllMessages(peerJID: String) {
        let jid = UserAPI.stripResourceFromJID(peerJID)
        if let chat = self.chatsMap[jid] {
            chat.unreadCount = 0
        }
    }
    
    func updatePushToken() {
        if let token = self.pushToken {
            let success = self.editProfile(["pushToken": token] , jsonCompletion: { HTTPJsonCompletion in
                print("Successfully pushed token for \(self.authToken!)")
            })
            if !success {
                print("Unable to push token for \(self.authToken!)")
            }
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
    
    var jpassword: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(self.jpassword, forKey: GGKey.userApiJabberdPassword)
        }
    }
   
    var username: String?
    var email: String?
    var password: String?
    var nickname: String?
    var avatarPath: String?
    var avatarImage: UIImage?
    var rosterList: [RosterUser] = [RosterUser]()
    var rosterMap: [String: RosterUser] = [String: RosterUser]()
    var chatsList: [ChatConversation] = [ChatConversation]()
    var chatsMap: [String: ChatConversation] = [String: ChatConversation]()
    var settings: UserSetting = UserSetting()
    
    var displayName: String {
        get {
            if let nickname = self.nickname {
                return nickname
            } else if let username = self.username {
                return username
            } else if let email = self.email {
                return email
            } else {
                return XMPPManager.sharedInstance.jid
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
                jsonCompletion?(json: nil)
            } else {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        data!,
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
                jsonCompletion?(json: nil)
            } else {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        data!,
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
                arrayCompletion?(array: nil)
            } else {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(
                        data!,
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