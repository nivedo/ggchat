//
//  GGWiki.swift
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

class GGWikiAsset : ImageModalAsset {
    var name: String
    var bundleId: Int
    var assetId: String
    var apiURL: String
    var fullName: String?
    var imageURL: String?
    var imageLocalURL: NSURL?
    var image: UIImage?
    var delegate: ImageModalAssetDelegate?
    
    init(name: String, bundleId: Int, assetId: String, fileType: String) {
        self.name = name
        self.fullName = name
        self.bundleId = bundleId
        self.assetId = assetId
        self.apiURL = GGWiki.apiURL(name)
        self.imageURL = "\(GGWiki.s3url)/\(bundleId)/\(assetId).\(fileType)"
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
    
    func fetchInfo() {
        print(self.imageURL)
        self.downloadImage()
    }
    
    func downloadImage() {
        if let urlImage = self.imageURL, let url = NSURL(string: urlImage) {
            getDataFromUrl(url) { (data, response, error)  in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    guard let data = data where error == nil else {
                        // print("Image download failed: \(error)")
                        self.delegate?.onDownloadError()
                        return
                    }
                    // print("Finished downloading \"\(url)\".")
                    self.image = UIImage(data: data)
                    if let image = self.image {
                        self.delegate?.onDownloadSuccess(image)
                    }
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

class GGWiki {
  
    enum WikiSet {
        case None
        case HearthStone
        case MagicTheGathering
    }
    
    class WikiResource {
        var title: String
        var name: String
        var fileType: String
        var icon: String
        var jsonURL: String
        var jsonData: NSData
        
        init(title: String, name: String, fileType: String, icon: String) {
            self.title = title
            self.name = name
            self.fileType = fileType
            self.icon = icon
            self.jsonURL = "\(GGWiki.s3url)/config/\(name).json"
            self.jsonData = NSData(contentsOfURL: NSURL(string: self.jsonURL)!)!
        }
    }
    
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
    
    class var sharedInstance: GGWiki {
        struct Singleton {
            static let instance = GGWiki()
        }
        return Singleton.instance
    }
  
    private var cardNames = [String]()
    private var cardNamesTrie = Trie()
    private var cardMaxTokens: Int = 1
    var cardAssets = [String : GGWikiAsset]()
    var cardNameToIdMap = [String : String]()
    var wikis = [WikiSet: WikiResource]()
    var autocompleteWiki: WikiSet = WikiSet.None
    
    init() {
        self.wikis[WikiSet.HearthStone] = WikiResource(
            title: "HearthStone",
            name: "hearthstone_en",
            fileType: "png",
            icon: "hearthstone-icon")
        self.wikis[WikiSet.MagicTheGathering] = WikiResource(
            title: "Magic The Gathering",
            name: "mtg_en_v2",
            fileType: "jpg",
            icon: "mtg-icon")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadAutocomplete(WikiSet.HearthStone)
            self.loadAssets()
        }
    }
   
    func loadAutocompleteAsync(wiki: WikiSet) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadAutocomplete(wiki)
        }
    }
    
    func loadAutocomplete(wiki: WikiSet) {
        if wiki != self.autocompleteWiki {
            self.resetAutocomplete()
            self.autocompleteWiki = wiki
            if let autocompleteResource = self.wikis[wiki] {
                self.loadAsset(autocompleteResource, forAutocomplete: true)
            }
        }
    }
    
    func loadAssets() {
        for (k, v) in self.wikis {
            if k != self.autocompleteWiki {
                self.loadAsset(v, forAutocomplete: false)
            }
        }
    }
    
    func resetAutocomplete() {
        self.autocompleteWiki = WikiSet.None
        self.cardNames = [String]()
        self.cardNamesTrie = Trie()
        self.cardMaxTokens = 1
        self.cardNameToIdMap = [String: String]()
        // self.cardAssets = [String: GGWikiAsset]()
    }
   
    func loadAsset(resource: WikiResource, forAutocomplete: Bool) {
        let json = try? NSJSONSerialization.JSONObjectWithData(
            resource.jsonData,
            options: NSJSONReadingOptions.AllowFragments)
        if let array = json as? NSArray {
            for bundle in array {
                if let dict = bundle as? NSDictionary {
                    if let cards = dict["assets"] as? NSArray, let bundleId = dict["bundleId"] as? Int {
                        // print("Number of wiki cards for bundle id \(bundleId): \(cards.count)")
                        var nameToIdMap = [String: String]()
                        for c in cards {
                            if let card = c as? NSDictionary {
                                if let cardName = card["name"] as? String, let assetId = card["id"] as? String {
                                    let lowercaseName = cardName.lowercaseString
                                    let id = AssetManager.id(bundleId, assetId: assetId)
                                    self.cardAssets[id] = GGWikiAsset(name: cardName, bundleId: bundleId, assetId: assetId, fileType: resource.fileType)
                                    if forAutocomplete {
                                        nameToIdMap[lowercaseName] = id
                                        self.cardNameToIdMap[lowercaseName] = id
                                        self.cardMaxTokens = max(self.cardMaxTokens, cardName.numTokens)
                                    }
                                }
                            }
                        }
                        for (k, _) in nameToIdMap {     // self.cardNameToIdMap {
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
            }
        }
    }
    
    /*
    func loadAsset(json: String, fileType: String, forAutocomplete: Bool) {
        if let asset = NSDataAsset(name: json, bundle: NSBundle.mainBundle()) {
            let json = try? NSJSONSerialization.JSONObjectWithData(
                asset.data,
                options: NSJSONReadingOptions.AllowFragments)
            if let dict = json as? NSDictionary {
                if let cards = dict["assets"] as? NSArray, let bundleId = dict["bundleId"] as? Int {
                    print("Number of wiki cards for bundle id \(bundleId): \(cards.count)")
                    var nameToIdMap = [String: String]()
                    for c in cards {
                        if let card = c as? NSDictionary {
                            if let cardName = card["name"] as? String, let assetId = card["id"] as? String {
                                let lowercaseName = cardName.lowercaseString
                                let id = AssetManager.id(bundleId, assetId: assetId)
                                self.cardAssets[id] = GGWikiAsset(name: cardName, bundleId: bundleId, assetId: assetId, fileType: fileType)
                                if forAutocomplete {
                                    nameToIdMap[lowercaseName] = id
                                    self.cardNameToIdMap[lowercaseName] = id
                                    self.cardMaxTokens = max(self.cardMaxTokens, cardName.numTokens)
                                }
                            }
                        }
                    }
                    for (k, _) in nameToIdMap {     // self.cardNameToIdMap {
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
                if let id = self.cardNameToIdMap[card] {
                    let score = 1.0 / Float(card.characters.count)
                    suggestions.append(AssetSortHelper(
                        str: card,
                        id: id,
                        replaceIndex: replaceIndex,
                        score: score))
                }
            }
        }
        self.activeSuggestionJobs--
        return suggestions
    }
}
