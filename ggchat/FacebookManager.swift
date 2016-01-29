//
//  FacebookManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/26/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class FacebookUser {
    var id: String
    var token: String
    var name: String
    var email: String
    var firstName: String?
    var lastName: String?
    var avatarUrl: String?
    
    init(id: String, token: String, result: AnyObject) {
        self.id = id
        self.token = token
        self.name = result.valueForKey("name") as! String
        self.email = result.valueForKey("email") as! String
        self.firstName = result.valueForKey("first_name") as? String
        self.lastName = result.valueForKey("last_name") as? String
        if let picture = result.valueForKey("picture") {
            if let data = picture.valueForKey("data") {
                if let url = data.valueForKey("url") as? String {
                    self.avatarUrl = url
                }
            }
        }
    }
    
    var userProfileJson: [String: AnyObject] {
        return [
            "facebookid" : self.id,
            "facebooktoken" : self.token,
            "nickname" : self.name,
            "username" : "facebookid_\(self.id)",
            "email" : self.email,
            "avatar" : (self.avatarUrl != nil) ? self.avatarUrl! : ""
        ]
    }
    
    var description: String {
        get {
            return "fbuser email: \(self.email), name: \(self.name)"
        }
    }
}

class FacebookManager {
    
    static let readPermissions = ["public_profile", "email", "user_friends"]
    
    var loginManager: FBSDKLoginManager!
    
    class var sharedInstance: FacebookManager {
        struct Singleton {
            static let instance = FacebookManager()
        }
        return Singleton.instance
    }
    
    init() {
        self.loginManager = FBSDKLoginManager()
    }
    
    class func fetchUserData(completion: ((FacebookUser?, String?) -> Void)?) {
        if let fbAccess = FBSDKAccessToken.currentAccessToken() {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(
                graphPath: "me",
                parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    completion?(nil, error.description)
                } else {
                    completion?(FacebookUser(id: fbAccess.userID, token: fbAccess.tokenString, result: result), nil)
                }
            })
        }
    }
    
    class func fetchFriendsData(completion: (([NSDictionary]?, String?) -> Void)?) {
        let fbRequest = FBSDKGraphRequest(
            graphPath:"/me/friends",
            // graphPath:"/me/taggable_friends",
            parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
        fbRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                if let friendObjects = result["data"] as? [NSDictionary] {
                    if friendObjects.count > 0 {
                        completion?(friendObjects, nil)
                        return
                    }
                }
                completion?(nil, "No friends using GG Chat")
            } else {
                completion?(nil, error.description)
            }
        }
    }
}