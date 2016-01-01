//
//  TappableText.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol TappableTextDelegate {
    
    func onTap(attributes: [String: AnyObject])
    func onTapCatchAll()
    
}

class TappableText: NSObject {
  
    static let tapSelector: String = "textTapped:"
    static let tapAttributeKey: String = "tappable"
    static let tapAssetId: String = "tapAssetId"
    
    static let alphaCharSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet
    static let punctuationCharSet = NSCharacterSet(charactersInString: ".!?;,")
    static let bracketCharSet = NSCharacterSet(charactersInString: "[]")
    
    // var lookup: [String] = [String]()
    var lookup: [String] = ["hey", "yo"]
    let delimiter = "&&"
    var delegate: TappableTextDelegate?
    
    class var sharedInstance: TappableText {
        struct Singleton {
            static let instance = TappableText()
        }
        return Singleton.instance
    }
    
    func imageModalAsset(id: String) -> ImageModalAsset? {
        return GGWiki.sharedInstance.cardAssets[id]
    }
    
    func tappableAttributedString(
        text: String,
        textColor: UIColor,
        highlightColor: Bool = true,
        textFont: UIFont? = nil,
        prevAttributedString: NSAttributedString? = nil) -> NSAttributedString {
            
        var paragraph = NSMutableAttributedString(string: "")
        if prevAttributedString != nil {
            paragraph = NSMutableAttributedString(attributedString: prevAttributedString!)
        }
      
        let tokens = text.componentsSeparatedByString(self.delimiter)
        for (_, token) in tokens.enumerate() {
            if token.length > 0 {
                var str = token
               
                // let (tappable, assetKey) = self.isTappableToken(token)
                let id = "\(self.delimiter)\(token)\(self.delimiter)"
                let asset = GGWiki.sharedInstance.getAsset(id)
                var tappable = false
                var assetId = str
                if let imageAsset = asset {
                    tappable = true
                    assetId = imageAsset.id
                    str = imageAsset.getDisplayName() // .capitalizedString
                }
                var attr: [String : NSObject] = [
                    NSFontAttributeName : (textFont != nil ? textFont! : GGConfig.messageBubbleFont),
                    NSForegroundColorAttributeName : (tappable && highlightColor) ? UIColor.gg_highlightedColor() : textColor
                ]
                if tappable {
                    attr[TappableText.tapAttributeKey] = tappable
                    attr[TappableText.tapAssetId] = assetId
                }
                
                let attributedString = NSAttributedString(
                    string: str,
                    attributes: attr)
                paragraph.appendAttributedString(attributedString)
            }
        }

        return paragraph.copy() as! NSAttributedString
    }
    
    func tappableEncodedString(
        text: String,
        textColor: UIColor) -> NSAttributedString {
        
        var paragraph = NSMutableAttributedString(string: "")
        let tokens = text.componentsSeparatedByString("||")
        for (_, token) in tokens.enumerate() {
            if token.length > 0 {
                let elements = token.componentsSeparatedByString("|")
                var str = token
                var attr: [String : NSObject] = [
                    NSFontAttributeName : GGConfig.messageBubbleFont,
                    NSForegroundColorAttributeName : textColor
                ]
                if elements.count == 3 {
                    let id = elements[0]
                    str = elements[2]
                    
                    attr[TappableText.tapAttributeKey] = true
                    attr[TappableText.tapAssetId] = id
                    attr[NSForegroundColorAttributeName] = UIColor.gg_highlightedColor()
                    
                    GGWiki.sharedInstance.addAsset(id, url: elements[1], displayName: str)
                }
                let attributedString = NSAttributedString(
                    string: str,
                    attributes: attr)
                paragraph.appendAttributedString(attributedString)
            }
        }

        return paragraph.copy() as! NSAttributedString
    }
    
    func textTapped(recognizer: UITapGestureRecognizer) {
        let textView: UITextView = recognizer.view as! UITextView
        
        // Location of the tap in text-container coordinates
        
        let layoutManager: NSLayoutManager = textView.layoutManager
        var location: CGPoint = recognizer.locationInView(textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        print("location: \(NSStringFromCGPoint(location))")
        
        // Find the character that's been tapped on
        
        let characterIndex: Int = layoutManager.characterIndexForPoint(location,
            inTextContainer: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil)
        
        if (characterIndex < textView.textStorage.length) {
            var range: NSRange = NSMakeRange(0, 1)
            let attributes: [String: AnyObject] = textView.textStorage.attributesAtIndex(characterIndex, effectiveRange: &range)
            
            if let tappable = attributes[TappableText.tapAttributeKey] as? Bool {
                if tappable {
                    print(attributes, NSStringFromRange(range))
                    self.delegate?.onTap(attributes)
                    return
                }
            }
        }
        self.delegate?.onTapCatchAll()
    }
}