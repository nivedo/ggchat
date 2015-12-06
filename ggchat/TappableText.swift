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
    static let tapAssetKey: String = "tapAsset"
    
    // var lookup: [String] = [String]()
    var lookup: [String] = ["hey", "yo"]
    let delimiter = " "
    var delegate: TappableTextDelegate?
    
    class var sharedInstance: TappableText {
        struct Singleton {
            static let instance = TappableText()
        }
        return Singleton.instance
    }
    
    func isTappableToken(token: String) -> (Bool, String) {
        let t = token.lowercaseString
        let k: String = t
        var tappable = self.lookup.contains(t)
        if !tappable {
            tappable = GGHearthStone.sharedInstance.isCard(t)
        }
        return (tappable, k)
    }
    
    func imageModalAsset(key: String) -> ImageModalAsset? {
        return GGHearthStone.sharedInstance.cardAssets[key]
    }
    
    func tappableAttributedString(
        text: String,
        textColor: UIColor,
        attributes: [String: NSObject]?,
        brackets: Bool = false) -> NSAttributedString {
        let paragraph = NSMutableAttributedString(string: "")
      
        let tokens = text.componentsSeparatedByString(self.delimiter)
        for (index, token) in tokens.enumerate() {
            var str = token
           
            let (tappable, assetKey) = self.isTappableToken(token)
            var attr: [String : NSObject] = [
                TappableText.tapAttributeKey : tappable,
                TappableText.tapAssetKey : assetKey,
                NSForegroundColorAttributeName : tappable ? UIColor.gg_highlightedColor() : textColor
            ]
            if let additionalAttr = attributes {
                for (key, value) in additionalAttr {
                    attr[key] = value
                }
            }
            if tappable && brackets {
                str = "[\(str)]"
            }
            
            if index < tokens.count - 1 {
                str += self.delimiter
            }
            let attributedString = NSAttributedString(
                string: str,
                attributes: attr)
            paragraph.appendAttributedString(attributedString)
        }
       
        if !brackets {
            assert(text.characters.count == paragraph.string.characters.count,
                "Original text \(text.characters.count) and tappable text \(paragraph.string.characters.count) must have same length.")
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