//
//  GGWiki.swift
//  ggchat
//
//  Created by Gary Chang on 12/4/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

/*
protocol ImageModalAssetDelegate {
    
    func onDownloadSuccess(image: UIImage)
    func onDownloadError()
    
}

protocol GGWikiDelegate {
    
    func onDownloadAsset(id: String, success: Bool)
}
*/

class AssetManager {
    
    class func id(bundleId: String, assetId: String) -> String {
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
    
    class func getSingleEncodedAsset(str: String) -> GGWikiAsset? {
        if str.length > 6 {
            if ((str[0...1] == "||") && (str[str.length-2..<str.length] == "||")) {
                let info = str[2..<str.length-2]
                let params = info.componentsSeparatedByString("|")
                if params.count == 3 {
                    if self.isSingleId(params[0]) {
                        return GGWiki.sharedInstance.getSingleAsset(str)
                    }
                }
            }
        }
        return nil
    }
    
}

class GGWikiAsset {
    var name: String
    var bundleId: String
    var assetId: String
    var fileType: String
    var imageURL: String
    var placeholderURL: String?
   
    var url: NSURL {
        get {
            return NSURL(string: self.imageURL)!
        }
    }
   
    init(name: String, bundleId: String, assetId: String, fileType: String, placeholderURL: String?) {
        self.name = name
        self.bundleId = bundleId
        self.assetId = assetId
        self.placeholderURL = placeholderURL
        self.fileType = fileType
        
        self.imageURL = "\(GGWiki.s3url)/\(bundleId)/\(assetId).\(fileType)"
      
        /*
        if let bundleURL = NSURL(string: "\(GGWiki.cacheFolderURL)/\(bundleId)") {
            let error = NSErrorPointer()
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(
                    bundleURL,
                    withIntermediateDirectories: true,
                    attributes: nil)
            } catch let error1 as NSError {
                error.memory = error1
                print("Creating '\(bundleURL)' directory failed. Error: \(error)")
            }
        }
        */
    }
    
    func getDisplayName() -> String {
        if self.name.gg_containsAsianCharacters {
            return "［\(self.name)］"
        } else {
            return "[\(self.name)]"
        }
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

class GGWikiCache {
    
    class var sharedInstance: GGWikiCache {
        struct Singleton {
            static let instance = GGWikiCache()
        }
        return Singleton.instance
    }

    var imageCache = [String: UIImage?]()
    
    init() {
        // Do nothing
    }
    
    func retreiveImage(key: String?) -> UIImage? {
        if let url = key {
            if let image = self.imageCache[url] {
                return image
            } else {
                if let data = NSData(contentsOfURL: NSURL(string: url)!) {
                    if let image = UIImage(data: data) {
                        self.imageCache[url] = image
                        return image
                    }
                }
            }
        }
        return nil
    }
}

class WikiResource {
    var name: String
    var icon: String
    var placeholder: String?
    var ref: String
    var jsonURL: String
    var jsonData: NSData
    var iconImage: UIImage?
    var placeholderURL: String?
    var language: String
   
    init(json: [String: String], language: String) {
        self.name = json["name"]!
        self.icon = json["icon"]!
        self.placeholder = json["placeholder"]
        self.ref = "\(json["ref"]!):\(language)"
        self.jsonURL = "\(GGWiki.s3url)/config/\(json["bundle"]!)"
        self.jsonData = NSData(contentsOfURL: NSURL(string: self.jsonURL)!)!
        
        let iconURL = "\(GGWiki.s3url)/assets/\(self.icon)"
        self.iconImage = GGWikiCache.sharedInstance.retreiveImage(iconURL)
       
        if let placeholder = self.placeholder {
            self.placeholderURL = "\(GGWiki.s3url)/assets/\(placeholder)"
            GGWikiCache.sharedInstance.retreiveImage(self.placeholderURL!)
        }
        self.language = language
    }
    
    var placeholderImage: UIImage? {
        get {
            if let url = self.placeholderURL {
                return GGWikiCache.sharedInstance.retreiveImage(url)
            } else {
                return nil
            }
        }
    }
}

class GGWiki {
    // private static let host = "http://45.33.39.21:1235"
    // private static let s3url = "https://s3-us-west-1.amazonaws.com/ggchat"
    private static let s3url = "http://d1fyt5lxvxva06.cloudfront.net"
    private static let cacheFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("wiki")
    static let maxDownloadAttempts = 2
 
    class func fileCacheURL(fileName: String) -> NSURL {
        let fileURL = self.cacheFolderURL.URLByAppendingPathComponent(fileName)
        return fileURL
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
    var wikisForBundleId = [String: WikiResource]()
    var autocompleteWiki: String? = nil
    // var delegate: GGWikiDelegate?
    
    init() {
        self.createCacheFolder()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadConfig()
            if let autocomplete = self.autocompleteWiki {
                print("Autocomplete \(autocomplete)")
                self.loadAutocomplete(autocomplete)
            }
            // self.loadAssets()
        }
    }
   
    func createCacheFolder() {
        let error = NSErrorPointer()
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                GGWiki.cacheFolderURL,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch let error1 as NSError {
            error.memory = error1
            print("Creating 'wiki' directory failed. Error: \(error)")
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
                            self.wikis[resource.ref] = resource
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
                print("Load asset \(v.ref)")
                self.loadAsset(v, forAutocomplete: false)
            }
        }
        for (_, v) in self.wikis {
            if v.language != UserAPI.sharedInstance.settings.language {
                print("Load asset \(v.ref)")
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
                    if let cards = dict["assets"] as? NSArray, let bundleIdInt = dict["bundleId"] as? Int, let fileType = dict["ext"] as? String {
                        let bundleId = "\(bundleIdInt)"
                        // print("Number of wiki cards for bundle id \(bundleId): \(cards.count)")
                        var cardNamesSet = Set<String>()
                        for c in cards {
                            if let card = c as? NSDictionary {
                                if let cardName = card["name"] as? String, let assetId = card["id"] as? String {
                                    let id = AssetManager.id(bundleId, assetId: assetId)
                                    if self.cardAssets[id] == nil {
                                        self.cardAssets[id] = GGWikiAsset(
                                            name: cardName,
                                            bundleId: bundleId,
                                            assetId: assetId,
                                            fileType: fileType,
                                            placeholderURL: resource.placeholderURL)
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
    
    func getSingleAsset(text: String) -> GGWikiAsset? {
        let tokens = text.componentsSeparatedByString("||")
        for (_, token) in tokens.enumerate() {
            if token.length > 0 {
                let elements = token.componentsSeparatedByString("|")
                if elements.count == 3 {
                    return GGWiki.sharedInstance.addAsset(elements[0], url: elements[1], displayName: elements[2])
                }
            }
        }
        return nil
    }
    
    func addAsset(id: String, url: String, displayName: String, placeholderURL: String? = nil) -> GGWikiAsset? {
        if id.rangeOfString("::") != nil && id.length > 6 && url.length > 0 && displayName.length > 2 {
           
            let idStrip = id[2..<id.length-2]
            let idTokens = idStrip.componentsSeparatedByString("::")
            if idTokens.count == 2 {
                let bundleId = idTokens[0]
                let assetId = idTokens[1]
               
                let urlTokens = url.componentsSeparatedByString(".")
                let fileType = urlTokens[urlTokens.count-1]
                
                let name = displayName[1..<displayName.length-1]
                if let asset = self.cardAssets[id] {
                    return asset
                } else {
                    let asset = GGWikiAsset(
                        name: name,
                        bundleId: bundleId,
                        assetId: assetId,
                        fileType: fileType,
                        placeholderURL: placeholderURL)
                    self.cardAssets[id] = asset
                    return asset
                }
            }
        }
        return nil
    }
    
    func getAssetImageURL(id: String) -> String {
        if id.rangeOfString("::") != nil {
            if let asset = self.cardAssets[id] {
                return asset.imageURL
            } else {
                print("NOT FOUND \(id)")
            }
        } else {
            print("ERROR \(id)")
        }
        return ""
    }
    
    func getAssetPlaceholderURL(id: String) -> String? {
        if let asset = self.cardAssets[id] {
            return asset.placeholderURL
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
            let replaceIndex = inputLength - target.characters.count
            if let s = self.computeCardSuggestion(target, replaceIndex: replaceIndex) {
                for h in s {
                    // Remove duplicate suggestions
                    if !suggestionIds.contains(h.id) {
                        suggestions.append(h)
                    }
                    suggestionIds.insert(h.id)
                }
            } else {
                return nil
            }
        }
        
        var results = [AssetAutocompleteSuggestion]()
        if suggestions.count > 0 {
            // results = suggestions.sort({ $0.score > $1.score }).map {
            results = suggestions.map {
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
