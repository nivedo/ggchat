//
//  UserAPI.swift
//  ggchat
//
//  Created by Gary Chang on 12/15/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias JSONCompletion = (json: [String: AnyObject]?) -> Void

class RosterUser {
    var nickname: String
    var jid: String
    var avatar: String
    var avatarImage: UIImage?
    
    init(profile: [String: AnyObject], avatarCompletion: ((Bool) -> Void)?) {
        self.jid = profile["jid"] as! String
        self.nickname = profile["nickname"] as! String
        self.avatar = profile["avatar"] as! String
        
        if self.avatar.length > 0 {
            print("Downloading avatar at \(self.avatar)")
            
            AWSS3DownloadManager.sharedInstance.download(
                self.avatar,
                userData: nil,
                completion: { (fileURL: NSURL) -> Void in
                    let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                    let image = UIImage(data: data)
                    self.avatarImage = image
                    avatarCompletion?(true)
                },
                bucket: GGSetting.awsS3AvatarsBucketName
            )
        } else {
            avatarCompletion?(false)
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

enum Language {
    case English
    case Japanese
    case ChineseTraditional
    case ChineseSimplified
}

class UserSetting {
    
    var minAutocompleteCharacters: Int = 2
    var language: Language {
        didSet {
            if self.language == Language.English {
                self.minAutocompleteCharacters = 2
            } else {
                self.minAutocompleteCharacters = 1
            }
        }
    }

    // Default settings
    init() {
        self.language = Language.English
        self.minAutocompleteCharacters = 2
        // self.language = Language.ChineseTraditional
        // self.minAutocompleteCharacters = 1
    }
    
}

class UserAPI {
    
    class var sharedInstance: UserAPI {
        struct Singleton {
            static let instance = UserAPI()
        }
        return Singleton.instance
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

    class var rosterUrl: String {
        return "\(self.route("rosterv2"))"
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
                    self.updatePushToken()
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
    }
   
    func authenticate(completion: ((Bool) -> Void)?) -> Bool {
        if let token = self.authToken {
            self.post(UserAPI.authUrl,
                authToken: token,
                jsonBody: nil,
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
   
    func getUserinfo(username: String, jsonCompletion: JSONCompletion) {
        self.get(UserAPI.userinfoUrl(username),
            authToken: nil,
            jsonCompletion: jsonCompletion)
    }

    func getRoster(jid: String, jsonCompletion: JSONCompletion) {
        if let token = self.authToken {
            self.get(UserAPI.rosterUrl,
                authToken: token,
                jsonCompletion: jsonCompletion)
        }
    }
    
    func getProfile(jsonCompletion: JSONCompletion) -> Bool {
        if let token = self.authToken {
            self.get(UserAPI.profileUrl,
                authToken: token,
                jsonCompletion: jsonCompletion
            )
            return true
        }
        return false
    }
    
    func editProfile(jsonBody: [String: AnyObject], jsonCompletion: JSONCompletion?) -> Bool {
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
                if let avatarPath = json["avatar"] as? String {
                    if avatarPath.length > 0 {
                        print("Downloading avatar at \(avatarPath)")
                        self.avatarPath = avatarPath
                        
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
                    }
                }
                completion?(true)
            }
        })
        completion?(false)
    }
    
    func cacheRoster(completion: ((Bool) -> Void)? = nil) {
        self.rosterList.removeAll()
        if let jid = self.jid {
            UserAPI.sharedInstance.getRoster(jid,
                jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                    if let json = jsonBody, let profiles = json["profiles"] as? NSArray {
                        // print(profiles)
                        for profile in profiles {
                            self.rosterList.append(RosterUser(
                                profile: profile as! [String: AnyObject],
                                avatarCompletion: completion))
                        }
                        completion?(true)
                        return
                    }
                    completion?(false)
                    return
                }
            )
        }
        completion?(false)
    }
    
    func updatePushToken() {
        if let token = self.pushToken {
            let success = self.editProfile(["pushToken": token] , jsonCompletion: { JSONCompletion in
                print("Successfully pushed token for \(self.authToken!)")
            })
            if !success {
                print("Unable to push token for \(self.authToken!)")
            }
        }
    }
    
    func updateAvatarImage(image: UIImage, jsonCompletion: JSONCompletion?) -> Bool {
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
    
    func updateNickname(nickname: String, jsonCompletion: JSONCompletion?) -> Bool {
        return self.editProfile(["nickname": nickname], jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
            if let _ = jsonBody {
                self.nickname = nickname
            }
            jsonCompletion?(json: jsonBody)
        })
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
    
    private func post(urlPath: String, authToken: String?, jsonBody: [String: AnyObject]?, jsonCompletion: JSONCompletion?) {
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
    
    private func get(urlPath: String, authToken: String?, jsonCompletion: JSONCompletion?) {
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
}