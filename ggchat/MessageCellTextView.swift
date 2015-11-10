//
//  MessageCellTextView.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageCellTextView: UITextView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.textColor = UIColor.whiteColor()
        self.editable =  false
        self.selectable = true
        self.userInteractionEnabled = true
        self.dataDetectorTypes = UIDataDetectorTypes.None
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.scrollEnabled = false
        self.backgroundColor = UIColor.clearColor()
        self.contentInset = UIEdgeInsetsZero
        self.scrollIndicatorInsets = UIEdgeInsetsZero
        self.contentOffset = CGPointZero
        self.textContainerInset = UIEdgeInsetsZero
        self.textContainer.lineFragmentPadding = 0
        let attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSUnderlineStyleAttributeName : (NSUnderlineStyle.StyleSingle.rawValue | NSUnderlineStyle.PatternSolid.rawValue)
        ]
        self.linkTextAttributes = attributes
    }

    override var selectedRange: NSRange {
        set {
            //  attempt to prevent selecting text
            self.selectedRange = NSMakeRange(NSNotFound, 0)
        }
        get {
            //  attempt to prevent selecting text
            return NSMakeRange(NSNotFound, NSNotFound)
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        //  ignore double-tap to prevent copy/define/etc. menu from showing
        if (gestureRecognizer.isKindOfClass(UITapGestureRecognizer)) {
            let tap: UITapGestureRecognizer = gestureRecognizer as! UITapGestureRecognizer
            if (tap.numberOfTapsRequired == 2) {
                return false
            }
        }
    return true
    }
    
    // TODO: This should be override
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        //  ignore double-tap to prevent copy/define/etc. menu from showing
        if (gestureRecognizer.isKindOfClass(UITapGestureRecognizer)) {
            let tap: UITapGestureRecognizer = gestureRecognizer as! UITapGestureRecognizer
            if (tap.numberOfTapsRequired == 2) {
                return false
            }
        }
        
        return true
    }
}
