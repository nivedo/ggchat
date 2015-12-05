//
//  GGHearthStone.swift
//  ggchat
//
//  Created by Gary Chang on 12/4/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class GGHearthStoneAsset {
    var name: String
    var apiURL: String
    var fullName: String?
    var imageURL: String?
    
    init(name: String) {
        self.name = name
        self.apiURL = GGHearthStone.apiURL(name)
    }
    
    enum JSONError: String, ErrorType {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    
    func apiFetchInfo() {
        guard let endpoint = NSURL(string: self.apiURL) else { print("Error creating endpoint");return }
        let request = NSMutableURLRequest(URL:endpoint)
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            do {
                guard let dat = data else { throw JSONError.NoData }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSDictionary else { throw JSONError.ConversionFailed }
                print(json)
                if let fullName = json["card"] as? String {
                    // print(fullName)
                    self.fullName = fullName
                }
                if let imageURL = json["image"] as? String {
                    // print(imageURL)
                    self.imageURL = imageURL
                } 
            } catch let error as JSONError {
                print(error.rawValue)
            } catch {
                print(error)
            }
            }.resume()
        }
}

class GGHearthStone {
   
    private static let host = "http://45.33.39.21:1235"
   
    class func apiURL(cardName: String) -> String {
        let urlName = cardName.stringByReplacingOccurrencesOfString(
            " ",
            withString: "",
            options: NSStringCompareOptions.LiteralSearch,
            range: nil)
        return "\(self.host)/images/\(urlName)"
    }
    
    class var sharedInstance: GGHearthStone {
        struct Singleton {
            static let instance = GGHearthStone()
        }
        return Singleton.instance
    }
  
    private var cardNames = [String]()
    private var cardAssets = [String : GGHearthStoneAsset]()
    
    init() {
        print("**************** HEARTHSTONE ******************")
        if let asset = NSDataAsset(name: "hearthstone-cards", bundle: NSBundle.mainBundle()) {
            let json = try? NSJSONSerialization.JSONObjectWithData(
                asset.data,
                options: NSJSONReadingOptions.AllowFragments)
            if let dict = json as? NSDictionary {
                if let cards = dict["data"] as? NSArray {
                    print("Number of hearthstone cards: \(cards.count)")
                    for c in cards {
                        if let card = c as? NSDictionary {
                            if let cardName = card["name"] as? String {
                                self.cardNames.append(cardName)
                                self.cardAssets[cardName] = GGHearthStoneAsset(name: cardName)
                            }
                        }
                    }
                }
            }
        } else {
            print("Error: Unable to find hearthstone-cards.json")
        }
    }
    
    func isCard(name: String) -> Bool {
        let valid = self.cardNames.contains(name)
       
        // Pre-fetch card if valid
        if valid {
            self.cardAssets[name]!.apiFetchInfo()
        }
        
        return valid
    }
    

}
