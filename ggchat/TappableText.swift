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
   
    /*
    func isTappableToken(token: String) -> (Bool, String) {
        var t = token.lowercaseString
        // t = t.componentsSeparatedByCharactersInSet(TappableText.alphaCharSet).joinWithSeparator("")
      
        // This will be temporary
        if let first = t.unicodeScalars.first {
            if TappableText.bracketCharSet.longCharacterIsMember(first.value) {
                t.removeAtIndex(t.startIndex)
            }
        }
        if let last = t.unicodeScalars.last {
            if TappableText.bracketCharSet.longCharacterIsMember(last.value) {
                t.removeAtIndex(t.endIndex.predecessor())
            }
        }
        
        if let last = t.unicodeScalars.last {
            if TappableText.punctuationCharSet.longCharacterIsMember(last.value) {
                t.removeAtIndex(t.endIndex.predecessor())
            }
        }
        
        let k: String = t
        var tappable = self.lookup.contains(t)
        if !tappable {
            tappable = GGHearthStone.sharedInstance.isCard(t)
        }
        return (tappable, k)
    }
    */
    
    func imageModalAsset(id: String) -> ImageModalAsset? {
        return GGHearthStone.sharedInstance.cardAssets[id]
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
                let asset = GGHearthStone.sharedInstance.getAsset(id)
                var tappable = false
                var assetId = str
                if let imageAsset = asset {
                    tappable = true
                    assetId = imageAsset.id
                    str = imageAsset.getDisplayName().capitalizedString
                }
                let attr: [String : NSObject] = [
                    TappableText.tapAttributeKey : tappable,
                    TappableText.tapAssetId : assetId,
                    NSFontAttributeName : (textFont != nil ? textFont! : GGConfig.messageBubbleFont),
                    NSForegroundColorAttributeName : (tappable && highlightColor) ? UIColor.gg_highlightedColor() : textColor
                ]
               
                /*
                if index < tokens.count - 1 {
                    str += self.delimiter
                }
                */
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