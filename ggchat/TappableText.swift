//
//  TappableText.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class TappableText: NSObject {
  
    static let tapSelector: String = "textTapped:"
    
    // var lookup: [String] = [String]()
    var lookup: [String] = ["hey", "yo"]
    
    class var sharedInstance: TappableText {
        struct Singleton {
            static let instance = TappableText()
        }
        return Singleton.instance
    }
    
    func tappableAttributedString(text: String) -> NSAttributedString {
        let paragraph = NSMutableAttributedString(string: text)
        
        let tests = [ "tap1", "tap2" ]
        for tap in tests {
            let attributedString = NSAttributedString(
                string: tap,
                attributes: [
                    "tappable" : true
                ]
            )
            paragraph.appendAttributedString(attributedString)
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
            print(attributes, NSStringFromRange(range))
            
            //Based on the attributes, do something
            ///if ([attributes objectForKey:...)] //make a network call, load a cat Pic, etc
            
        }
    }
}