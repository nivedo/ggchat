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
    
    class func isSingleId(str: String) -> Bool {
        let tokens = str.tokens
        if tokens.count == 1 {
            let id = tokens[0]
            if id.length > 6 {
                if ((id[0...1] == "&&") && (id[id.length-2..<id.length] == "&&") && id.rangeOfString("::") != nil) {
                    return true
                }
            }
        }
        return false
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
        return "\(UserAPI.sharedInstance.settings.bracketOpen)\(self.name)\(UserAPI.sharedInstance.settings.bracketClose)"
        // return self.name
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
    
    func downloadImage() {
        if self.image == nil {
            if let urlImage = self.imageURL, let url = NSURL(string: urlImage) {
                getDataFromUrl(url) { (data, response, error)  in
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        guard let data = data where error == nil else {
                            print("Image download failed: \(error)")
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
  
    class WikiResource {
        var name: String
        var icon: String
        var ref: String
        var bundle: String
        var jsonURL: String
        var jsonData: NSData
        var iconImage: UIImage?
        var language: String
       
        init(json: [String: String], language: String) {
            self.name = json["name"]!
            self.icon = json["icon"]!
            self.ref = json["ref"]!
            self.bundle = "\(self.ref):\(language)"
            self.jsonURL = "\(GGWiki.s3url)/config/\(json["bundle"]!)"
            self.jsonData = NSData(contentsOfURL: NSURL(string: self.jsonURL)!)!
            
            let iconURL = "\(GGWiki.s3url)/assets/\(self.icon)"
            self.iconImage = UIImage(data: NSData(contentsOfURL: NSURL(string: iconURL)!)!)
            self.language = language
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
    
    class var configURL: String {
        let url = "\(self.s3url)/config/config.json"
        return url
    }
    
    class var sharedInstance: GGWiki {
        struct Singleton {
            static let instance = GGWiki()
        }
        return Singleton.instance
    }
  
    private var cardNamesTrie = Trie()
    private var cardMaxTokens: Int = 1
    var cardAssets = [String : GGWikiAsset]()
    var cardNameToIdMap = [String : String]()
    var wikis = [String: WikiResource]()
    var autocompleteWiki: String? = nil
    
    init() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadConfig()
            if let autocomplete = self.autocompleteWiki {
                print("Autocomplete \(autocomplete)")
                self.loadAutocomplete(autocomplete)
            }
            self.loadAssets()
        }
    }
   
    func loadConfig() {
        if let configData = NSData(contentsOfURL: NSURL(string: GGWiki.configURL)!) {
            let json = try? NSJSONSerialization.JSONObjectWithData(
            configData,
            options: NSJSONReadingOptions.AllowFragments)
            if let dict = json as? NSDictionary {
                for (language, languageBundles) in dict {
                    if let bundles = languageBundles as? NSArray {
                        // print(bundles)
                        for wikiJson in bundles {
                            let resource = WikiResource(
                                json: wikiJson as! [String: String],
                                language: language as! String)
                            self.wikis[resource.bundle] = resource
                        }
                    }
                }
            }
        }
    }
    
    func getAutocompleteResource() -> WikiResource? {
        if let auto = self.autocompleteWiki {
            return self.wikis[auto]
        }
        return nil
    }
   
    func loadAutocompleteAsync(wiki: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadAutocomplete(wiki)
        }
    }
    
    func loadAutocomplete(wiki: String) {
        if wiki != self.autocompleteWiki {
            self.resetAutocomplete()
            self.autocompleteWiki = wiki
            if let autocompleteResource = self.wikis[wiki] {
                self.loadAsset(autocompleteResource, forAutocomplete: true)
            }
        }
    }
    
    func loadAssets() {
        // Load asset bundles in the user's language first
        for (_, v) in self.wikis {
            if v.language == UserAPI.sharedInstance.settings.language {
                print("Load asset \(v.bundle)")
                self.loadAsset(v, forAutocomplete: false)
            }
        }
        for (_, v) in self.wikis {
            if v.language != UserAPI.sharedInstance.settings.language {
                print("Load asset \(v.bundle)")
                self.loadAsset(v, forAutocomplete: false)
            }
        }
    }
    
    func resetAutocomplete() {
        self.autocompleteWiki = nil
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
                    if let cards = dict["assets"] as? NSArray, let bundleId = dict["bundleId"] as? Int, let fileType = dict["ext"] as? String {
                        // print("Number of wiki cards for bundle id \(bundleId): \(cards.count)")
                        var cardNamesSet = Set<String>()
                        for c in cards {
                            if let card = c as? NSDictionary {
                                if let cardName = card["name"] as? String, let assetId = card["id"] as? String {
                                    let id = AssetManager.id(bundleId, assetId: assetId)
                                    if self.cardAssets[id] == nil {
                                        self.cardAssets[id] = GGWikiAsset(name: cardName, bundleId: bundleId, assetId: assetId, fileType: fileType)
                                    }
                                    if forAutocomplete {
                                        cardNamesSet.insert(cardName)
                                        self.cardNameToIdMap[cardName] = id
                                        self.cardMaxTokens = max(self.cardMaxTokens, cardName.numTokens)
                                    }
                                }
                            }
                        }
                        for k in cardNamesSet {
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
    
    func getAsset(id: String) -> ImageModalAsset? {
        if id.rangeOfString("::") != nil {
            if let asset = self.cardAssets[id] {
                asset.downloadImage()
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
    
    func getCardSuggestions(name: String, inputLength: Int) -> [AssetAutocompleteSuggestion]? {
        
        let numTokens = min(name.numTokens, self.cardMaxTokens)
        let tokens = name.componentsSeparatedByCharactersInSet(
            NSCharacterSet.whitespaceCharacterSet())
        var suggestions = [AssetSortHelper]()
        var suggestionIds = Set<String>()
        
        for i in (1...numTokens).reverse() {
            let startIndex: Int = tokens.count - i
            let lastTokens = tokens[startIndex..<tokens.count]
            
            let target = lastTokens.joinWithSeparator(" ")
            // let replaceIndex = name.characters.count - target.characters.count
            let replaceIndex = inputLength - target.characters.count
            if let s = self.computeCardSuggestion(target, replaceIndex: replaceIndex) {
                for h in s {
                    if !suggestionIds.contains(h.id) {
                        suggestions.append(h)
                    }
                    suggestionIds.insert(h.id)
                }
                // suggestions.appendContentsOf(s)
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
    
    private func computeCardSuggestion(name: String, replaceIndex: Int) -> [AssetSortHelper]? {
        print("compute \(name), lower: \(name.lowercaseString), count: \(name.characters.count), (\(self.activeSuggestionJobs))")
        
        if self.activeSuggestionJobs > 0 {
            return nil
        }
        
        var suggestions = [AssetSortHelper]()
        // Short-circuit if asset id
        if (name.rangeOfString("::") != nil && name.rangeOfString("&") != nil) {
            return suggestions
        }
        
        if name.characters.count < UserAPI.sharedInstance.settings.minAutocompleteCharacters {
            return suggestions
        }
        self.activeSuggestionJobs++
        
        if let cardList = self.cardNamesTrie.findWordAndPrefix(name) {
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
