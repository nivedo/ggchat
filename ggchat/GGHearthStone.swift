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
    
}

class GGHearthStoneAsset : ImageModalAsset {
    var name: String
    var apiURL: String
    var fullName: String?
    var imageURL: String?
    var imageLocalURL: NSURL?
    var image: UIImage?
    var delegate: ImageModalAssetDelegate?
    
    init(name: String) {
        self.name = name
        self.apiURL = GGHearthStone.apiURL(name)
    }
    
    func getUIImage() -> UIImage? {
        return self.image
    }
    
    enum JSONError: String, ErrorType {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    
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
    var cardAssets = [String : GGHearthStoneAsset]()
    
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
            self.cardAssets[name]!.fetchInfo()
        }
        
        return valid
    }
    

}
