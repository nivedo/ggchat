//
//  FacebookManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/26/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class FacebookManager {
    
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
    
    class func userData() {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(
            graphPath: "me",
            parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
            } else {
                print("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                print("User Name is: \(userName)")
                let userEmail = result.valueForKey("email") as? String
                print("User Email is: \(userEmail)")
                let token = FBSDKAccessToken.currentAccessToken()
                let userToken = token.tokenString
                let userId = token.userID
                print("User token: \(userToken), id: \(userId)")
            }
        })
    }
    
    class func friendsData() {
        let fbRequest = FBSDKGraphRequest(
            graphPath:"/me/friends",
            // graphPath:"/me/taggable_friends",
            parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
        fbRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                print("Friends are : \(result)")
                let friendObjects = result["data"] as! [NSDictionary]
                for friendObject in friendObjects {
                    print(friendObject["id"])
                }
                print("Count of friends with app: \(friendObjects.count)")
            } else {
                print("Error Getting Friends \(error)");
            }
        }
    }
}