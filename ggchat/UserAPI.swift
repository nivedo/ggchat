//
//  UserAPI.swift
//  ggchat
//
//  Created by Gary Chang on 12/15/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public typealias JSONCompletion = (json: [String: AnyObject]?) -> Void

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
    
    ////////////////////////////////////////////////////////////////////
    
    func register(email: String, password: String, completion: ((Bool) -> Void)?) {
        self.post(UserAPI.registerUrl,
            authToken: nil,
            jsonBody: [ "email": email, "password": password ],
            jsonCompletion: { (jsonDict: [String: AnyObject]?) -> Void in
                if let json = jsonDict,
                let newToken = json["token"] as? String,
                let jid = json["jid"] as? String,
                let pass = json["pass"] as? String
                {
                    self.authToken = newToken
                    self.jid = jid
                    self.pass = pass
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
                    self.jid = jid
                    self.pass = pass
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
    }
    
    func authenticate(completion: ((Bool) -> Void)?) -> Bool {
        if let token = self.authToken {
            self.post(UserAPI.loginUrl,
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
                        self.pass = pass
                        completion?(true)
                    } else {
                        completion?(false)
                    }
            })
            return true
        }
        return false
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
    
    func editProfile(jsonBody: [String: AnyObject], jsonCompletion: JSONCompletion) -> Bool {
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
    
    ////////////////////////////////////////////////////////////////////
    
    private var authToken: String?
    private var jid: String?
    private var pass: String?
    
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