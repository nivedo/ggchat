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
typealias HTTPMessagesCompletion = (messages: [Message]?) -> Void

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
            /*
            AWSS3DownloadManager.sharedInstance.download(
                self.avatar,
                userData: nil,
                completion: { (fileURL: NSURL) -> Void in
                    let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                    let image = UIImage(data: data)
                    self.avatarImage = image
                    avatarCompletion?(true)
                    UserAPI.sharedInstance.delegate?.onAvatarUpdate(self.jid, success: true)
                },
                bucket: GGSetting.awsS3AvatarsBucketName
            )
            */
        } else {
            avatarCompletion?(false)
            UserAPI.sharedInstance.delegate?.onAvatarUpdate(self.jid, success: false)
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
                return MessageAvatarImageFactory.avatarImageWithImage(image, diameter: GGConfig.avatarSize)
            } else {
                let tokens = self.displayName.tokens
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
        }
    }
}

class ChatConversation {
    var peerJID: String!
    var lastTime: NSDate!
    var lastMessage: Message!
    
    init(json: [String: AnyObject]) {
        if let timestamp = json["time"] as? NSTimeInterval,
            let jid = json["peer"] as? String,
            let xmlStr = json["xml"] as? String {
            self.peerJID = jid
            if let msg = UserAPI.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: nil) {
                self.lastTime = msg.date
                self.lastMessage = msg
            }
        }
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

    class var rosterUrl: String {
        return "\(self.route("rosterv3"))"
    }

    class var chatsUrl: String {
        return "\(self.route("chats"))"
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
            url = "\(url)&end=\(endDate.timeIntervalSince1970 * 1e6)"
        }
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
                    self.cacheProfile(nil)
                    self.cacheRoster()
                    self.cacheChats()
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
        // print("Authenticate with \(self.authToken)")
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
                        self.cacheProfile(nil)
                        self.cacheRoster()
                        self.cacheChats()
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
    
    func cacheProfile(completion: ((Bool) -> Void)?) {
        self.getProfile({ (jsonResponse: [String: AnyObject]?) -> Void in
            if let json = jsonResponse {
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
                        
                        /*
                        AWSS3DownloadManager.sharedInstance.download(
                            avatarPath,
                            userData: nil,
                            completion: { (fileURL: NSURL) -> Void in
                                let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                                let image = UIImage(data: data)
                                self.avatarImage = image
                            },
                            bucket: GGSetting.awsS3AvatarsBucketName
                        )
                        */
                    }
                }
                completion?(true)
            }
        })
        completion?(false)
    }
    
    func cacheRoster(completion: ((Bool) -> Void)? = nil) {
        if let jid = self.jid {
            UserAPI.sharedInstance.getRoster(jid,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        // print(profiles)
                        self.rosterList.removeAll()
                        self.rosterMap.removeAll()
                        for profile in array {
                            let user = RosterUser(
                                profile: profile as! [String: AnyObject],
                                avatarCompletion: completion)
                            self.rosterList.append(user)
                            self.rosterMap[user.jid] = user
                        }
                        self.rosterList.sortInPlace({ $0.displayName.lowercaseString < $1.displayName.lowercaseString })
                        completion?(true)
                        self.delegate?.onRosterUpdate(true)
                        return
                    }
                    completion?(false)
                    self.delegate?.onRosterUpdate(false)
                    return
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
       
        // let to = element.attributeStringValueForName("to")
        
        if let bodyElement = element?.elementForName("body"),
            let from = element?.attributeStringValueForName("from"),
            let type = element?.attributeStringValueForName("type") {
            if type != "chat" {
                print(xmlString)
                return nil
            }
                
            let id = element?.attributeStringValueForName("id")
            
            let body = bodyElement.stringValue()
            let fromBare = UserAPI.stripResourceFromJID(from)
            
            if let _ = bodyElement.elementForName("photo") {
                if let photoMessage = S3PhotoManager.sharedInstance.getPhotoMessage(bodyElement, completion: nil, delegate: delegate) {
                    photoMessage.id = id
                    return photoMessage
                }
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
    
    func getHistory(peerJID: String, end: NSDate?, delegate: MessageMediaDelegate?, completion: HTTPMessagesCompletion? = nil) {
        // print("getHistory")
        if let token = self.authToken {
            self.get(UserAPI.historyUrl(peerJID, limit: nil, end: end),
                authToken: token,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        // print(array)
                        var messages = [Message]()
                        for element in array {
                            if let json = element as? [String: AnyObject] {
                                if let xmlStr = json["xml"] as? String, let timestamp = json["time"] as? NSTimeInterval {
                                    if let msg = UserAPI.parseMessageFromString(xmlStr, timestamp: timestamp / 1e6, delegate: delegate) {
                                        messages.append(msg)
                                    }
                                }
                            }
                        }
                        completion?(messages: messages)
                    } else {
                        print("Failed to load history for \(peerJID)")
                        completion?(messages: nil)
                    }
                })
        }
    }
    
    func cacheChats() {
        if let token = self.authToken {
            print(UserAPI.chatsUrl)
            self.get(UserAPI.chatsUrl,
                authToken: token,
                arrayCompletion: { (arrayBody: [AnyObject]?) -> Void in
                    if let array = arrayBody {
                        self.chatsList.removeAll()
                        self.chatsMap.removeAll()
                        for element in array {
                            if let json = element as? [String: AnyObject] {
                                // print(json)
                                let chat = ChatConversation(json: json)
                                self.chatsList.append(chat)
                                self.chatsMap[chat.peerJID] = chat
                            }
                        }
                        self.delegate?.onChatsUpdate(true)
                    } else {
                        self.delegate?.onChatsUpdate(false)
                    }
                    // print("chat list count: \(self.chatsList.count)")
            })
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
        let tokens = jid.tokens
        let initials = tokens[0].substringToIndex(tokens[0].startIndex.advancedBy(1))
        return MessageAvatarImageFactory.avatarImageWithUserInitials(
            initials,
            backgroundColor: UIColor(white: 0.85, alpha: 1.0),
            textColor: UIColor(white: 0.60, alpha: 1.0),
            font: UIFont.systemFontOfSize(14.0),
            diameter: GGConfig.avatarSize)
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
                let avatar = MessageAvatarImageFactory.avatarImageWithImage(image, diameter: GGConfig.avatarSize)
                return avatar
            } else {
                return GGModelData.sharedInstance.getAvatar(self.jid!, displayName: self.displayName)
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