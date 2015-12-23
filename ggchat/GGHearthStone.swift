//
//  GGHearthStone.swift
//  ggchat
//
//  Created by Gary Chang on 12/4/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

protocol ImageModalAssetDelegate {
    
    func onDownloadSuccess(image: UIImage)
    func onDownloadError()
    
}

protocol ImageModalAsset {
    
    var delegate: ImageModalAssetDelegate? { get set }
    func getUIImage() -> UIImage?
    func getDisplayName() -> String
    var id: String { get }
    var key: String { get }
    
}

class AssetManager {
    
    class func id(bundleId: Int, assetId: String) -> String {
        return "&&\(bundleId)::\(assetId)&&"
    }
    
}

class GGHearthStoneAsset : ImageModalAsset {
    var name: String
    var bundleId: Int
    var assetId: String
    var apiURL: String
    var fullName: String?
    var imageURL: String?
    var imageLocalURL: NSURL?
    var image: UIImage?
    var delegate: ImageModalAssetDelegate?
    
    init(name: String, bundleId: Int, assetId: String) {
        self.name = name
        self.fullName = name
        self.bundleId = bundleId
        self.assetId = assetId
        self.apiURL = GGHearthStone.apiURL(name)
        self.imageURL = "\(GGHearthStone.s3url)/\(bundleId)/\(assetId).png"
    }
    
    func getUIImage() -> UIImage? {
        return self.image
    }
    
    func getDisplayName() -> String {
        return "[\(self.name)]"
    }
    
    var id: String {
        get {
            return AssetManager.id(self.bundleId, assetId: self.assetId)
        }
    }
    
    var key: String {
        get {
            return self.name.lowercaseString
        }
    }
    
    enum JSONError: String, ErrorType {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
   
    /*
    func fetchInfo() {
        guard let endpoint = NSURL(string: self.apiURL) else { print("Error creating endpoint");return }
        let request = NSMutableURLRequest(URL:endpoint)
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            do {
                guard let dat = data else { throw JSONError.NoData }
                guard let json = try NSJSONSerialization.JSONObjectWithData(dat, options: []) as? NSDictionary else { throw JSONError.ConversionFailed }
                // print(json)
                if let fullName = json["card"] as? String {
                    // print(fullName)
                    self.fullName = fullName
                }
                if let imageURL = json["image"] as? String {
                    // print(imageURL)
                    self.imageURL = imageURL
                    self.downloadImage()
                } 
            } catch let error as JSONError {
                print(error.rawValue)
            } catch {
                print(error)
            }
            }.resume()
        }
    */
    
    func fetchInfo() {
        print(self.imageURL)
        self.downloadImage()
    }
    
    func downloadImage() {
        if let urlImage = self.imageURL, let url = NSURL(string: urlImage) {
            // print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
            // print("Started downloading \"\(url)\".")
            getDataFromUrl(url) { (data, response, error)  in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    guard let data = data where error == nil else {
                        // print("Image download failed: \(error)")
                        self.delegate?.onDownloadError()
                        return
                    }
                    // print("Finished downloading \"\(url)\".")
                    self.image = UIImage(data: data)
                    self.delegate?.onDownloadSuccess(self.image!)
                }
            }
        }
    }
    
    func saveImage() {
        if let image = self.image {
            let imageData = UIImagePNGRepresentation(image)
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let imageURL = documentsURL.URLByAppendingPathComponent("\(self.name).png")
            
            if !imageData!.writeToURL(imageURL, atomically: false) {
                print("Asset not saved")
            } else {
                print("Asset saved at \(imageLocalURL)")
                // NSUserDefaults.standardUserDefaults().setObject(imageURL, forKey: "imagePath")
                self.imageLocalURL = imageURL
            }
        }
    }
    
    func loadSavedImage() {
        if let localUrl = self.imageLocalURL, let imageData = NSData(contentsOfURL: localUrl) {
            self.image = UIImage(data: imageData)
        }
    }
    
    func deleteSavedImage() {
        if let localUrl = self.imageLocalURL {
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtURL(localUrl)
            } catch {
                print("Cannot delete file at \(localUrl)")
            }
        }
    }
    
    func getDataFromUrl(url:NSURL,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
}

extension String {
    
    var numTokens: Int {
        get {
            let tokens = self.componentsSeparatedByCharactersInSet(
                NSCharacterSet.whitespaceCharacterSet())
            return tokens.count
        }
    }
    
    var tokens: [String] {
        get {
            let tokens = self.componentsSeparatedByCharactersInSet(
                NSCharacterSet.whitespaceCharacterSet())
            return tokens
        }
    }
}

class GGHearthStone {
   
    private static let host = "http://45.33.39.21:1235"
    private static let s3url = "https://s3-us-west-1.amazonaws.com/ggchat"
    
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
    private var cardNamesTrie = Trie()
    private var cardMaxTokens: Int = 1
    var cardAssets = [String : GGHearthStoneAsset]()
    var cardNameToIdMap = [String : String]()
   
    /*
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
                                
                                self.cardMaxTokens = max(self.cardMaxTokens, cardName.numTokens)
                            }
                        }
                    }
                }
            }
        } else {
            print("Error: Unable to find hearthstone-cards.json")
        }
    }
    */
    
    init() {
        print("**************** HEARTHSTONE ******************")
        self.loadAsset("hearthstone_en")
        // self.loadAsset("mtg_en")
    }
    
    func loadAsset(json: String) {
        if let asset = NSDataAsset(name: json, bundle: NSBundle.mainBundle()) {
            let json = try? NSJSONSerialization.JSONObjectWithData(
                asset.data,
                options: NSJSONReadingOptions.AllowFragments)
            if let dict = json as? NSDictionary {
                if let cards = dict["assets"] as? NSArray, let bundleId = dict["bundleId"] as? Int {
                    print("Number of hearthstone cards: \(cards.count)")
                    for c in cards {
                        if let card = c as? NSDictionary {
                            if let cardName = card["name"] as? String, let assetId = card["id"] as? String {
                                let lowercaseName = cardName.lowercaseString
                                let id = AssetManager.id(bundleId, assetId: assetId)
                                self.cardAssets[id] = GGHearthStoneAsset(name: cardName, bundleId: bundleId, assetId: assetId)
                                self.cardNameToIdMap[lowercaseName] = id
                                
                                self.cardMaxTokens = max(self.cardMaxTokens, cardName.numTokens)
                            }
                        }
                    }
                    for (k, _) in self.cardNameToIdMap {
                        self.cardNames.append(k)
                        self.cardNamesTrie.addWord(k)
                        
                        for (index, word) in k.tokens.enumerate() {
                            if index > 0 && word.length >= 4 {
                                self.cardNamesTrie.addPrefix(word, finalWord: k)
                            }
                        }
                    }
                }
            }
        } else {
            print("Error: Unable to find \(json)")
        }
    }
   
    /*
    func isCard(id: String) -> Bool {
        /*
        let valid = self.cardNames.contains(id)
       
        // Pre-fetch card if valid
        if valid {
            self.cardAssets[id]!.fetchInfo()
        }
        
        return valid
        */
        // print(id)
        if (id[id.startIndex] == "&" && id.rangeOfString("::") != nil) {
            print("is asset id")
            if let name = self.cardIdToNameMap[id] {
                self.cardAssets[name]!.fetchInfo()
                return true
            }
        }
        return false
    }
    */
    
    func getAsset(id: String) -> ImageModalAsset? {
        if id.rangeOfString("::") != nil {
            if let asset = self.cardAssets[id] {
                asset.fetchInfo()
                return asset
            }
        }
        return nil
    }
   
    class AssetSortHelper {
        var str: String
        var id: String
        var replaceIndex: Int
        var score: Float
        
        init(str: String, id: String, replaceIndex: Int, score: Float) {
            self.str = str
            self.id = id
            self.replaceIndex = replaceIndex
            self.score = score
        }
    }
    
    func getCardSuggestions(name: String, inputLength: Int, threshold: Float = 0.7) -> [AssetAutocompleteSuggestion]? {
        
        let numTokens = min(name.numTokens, self.cardMaxTokens)
        let tokens = name.componentsSeparatedByCharactersInSet(
            NSCharacterSet.whitespaceCharacterSet())
        var suggestions = [AssetSortHelper]()
        
        for i in 1...numTokens {
            let startIndex: Int = tokens.count - i
            let lastTokens = tokens[startIndex..<tokens.count]
            
            let target = lastTokens.joinWithSeparator(" ")
            // let replaceIndex = name.characters.count - target.characters.count
            let replaceIndex = inputLength - target.characters.count
            if let s = self.computeCardSuggestion(target, replaceIndex: replaceIndex, threshold: threshold, matchPrefixAfterChars: 4) {
                suggestions.appendContentsOf(s)
            } else {
                return nil
            }
        }
        
        var results = [AssetAutocompleteSuggestion]()
        if suggestions.count > 0 {
            results = suggestions.sort({ $0.score > $1.score }).map {
                (let helper) -> AssetAutocompleteSuggestion in
                return AssetAutocompleteSuggestion(
                    displayString: helper.str,
                    replaceIndex: helper.replaceIndex,
                    id: helper.id)
            }
        }
       
        return results
    }
    
    var activeSuggestionJobs: Int = 0
    
    private func computeCardSuggestion(name: String, replaceIndex: Int, threshold: Float, matchPrefixAfterChars: Int) -> [AssetSortHelper]? {
        print("compute \(name) (\(self.activeSuggestionJobs))")
        
        if self.activeSuggestionJobs > 0 {
            return nil
        }
        
        var suggestions = [AssetSortHelper]()
        // Short-circuit if asset id
        if (name.rangeOfString("::") != nil && name.rangeOfString("&") != nil) {
            return suggestions
        }
        
        if name.characters.count <= 1 {
            return suggestions
        }
        self.activeSuggestionJobs++
        
        let lowercaseName = name.lowercaseString
       
        if let cardList = self.cardNamesTrie.findWordAndPrefix(lowercaseName) {
            for card in cardList {
                let score = 1.0 / Float(card.characters.count)
                suggestions.append(AssetSortHelper(
                    str: card,
                    id: self.cardNameToIdMap[card]!,
                    replaceIndex: replaceIndex,
                    score: score))
            }
        }
        self.activeSuggestionJobs--
        return suggestions
    }
}
