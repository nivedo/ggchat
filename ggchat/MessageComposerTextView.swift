//
//  MessageComposerTextView.swift
//  ggchat
//
//  Created by Gary Chang on 11/18/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

protocol MessageComposerTextViewPasteDelegate {

    /**
     *  Asks the delegate whether or not the `textView` should use the original implementation of `-[UITextView paste]`.
     *
     *  @discussion Use this delegate method to implement custom pasting behavior. 
     *  You should return `NO` when you want to handle pasting. 
     *  Return `YES` to defer functionality to the `textView`.
     */
    func composerTextView(textView: MessageComposerTextView,
        shouldPasteWithSender sender: AnyObject?) -> Bool

}

class MessageComposerTextView: UITextView {

    // pragma mark - Initialization
    var pasteDelegate: MessageComposerTextViewPasteDelegate?

    func gg_configureTextView() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let cornerRadius: CGFloat = 6.0
        
        self.backgroundColor = UIColor.whiteColor()
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.layer.cornerRadius = cornerRadius
        
        self.scrollIndicatorInsets = UIEdgeInsetsMake(cornerRadius, 0.0, cornerRadius, 0.0)
        
        self.textContainerInset = UIEdgeInsetsMake(4.0, 2.0, 4.0, 2.0)
        self.contentInset = UIEdgeInsetsMake(1.0, 0.0, 1.0, 0.0)
        
        self.scrollEnabled = true
        self.scrollsToTop = false
        self.userInteractionEnabled = true
        
        self.font = UIFont.systemFontOfSize(16.0)
        self.textColor = UIColor.blackColor()
        self.textAlignment = NSTextAlignment.Natural
        
        self.contentMode = UIViewContentMode.Redraw
        self.dataDetectorTypes = UIDataDetectorTypes.None
        self.keyboardAppearance = UIKeyboardAppearance.Default
        self.keyboardType = UIKeyboardType.Default
        self.returnKeyType = UIReturnKeyType.Default
        
        self.text = nil
        
        self.placeHolder = nil
        self.placeHolderTextColor = UIColor.lightGrayColor()
        
        self.gg_addTextViewNotificationObservers()
    }
 
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.gg_configureTextView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.gg_configureTextView()
    }

    // pragma mark - Composer text view

    override func hasText() -> Bool {
        return (self.text.gg_stringByTrimingWhitespace().characters.count > 0)
    }

    // pragma mark - Setters

    var placeHolder: String? {
        didSet {
            if (self.placeHolder != oldValue) {
                self.setNeedsDisplay()
            }
        }
    }

    var placeHolderTextColor: UIColor = UIColor.lightGrayColor() {
        didSet {
            if (self.placeHolderTextColor != oldValue) {
                self.setNeedsDisplay()
            }
        }
    }

    // pragma mark - UITextView overrides

    override var text: String! {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override var font: UIFont! {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func paste(sender: AnyObject?) {
        if (self.pasteDelegate == nil ||
            self.pasteDelegate!.composerTextView(
            self,
            shouldPasteWithSender: sender)) {
            super.paste(sender)
        }
    }

    // pragma mark - Drawing
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        super.drawRect(rect)
    
        if (self.text.characters.count == 0 && self.placeHolder != nil) {
            self.placeHolderTextColor.set()
            
            self.placeHolder!.drawInRect(
                CGRectInset(rect, 7.0, 5.0),
                withAttributes: self.gg_placeholderTextAttributes())
        }
    }

    // pragma mark - Notifications

    func gg_addTextViewNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("gg_didReceiveTextViewNotification:"),
            name: UITextViewTextDidChangeNotification,
            object: self)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("gg_didReceiveTextViewNotification:"),
            name: UITextViewTextDidBeginEditingNotification,
            object: self)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("gg_didReceiveTextViewNotification:"),
            name: UITextViewTextDidEndEditingNotification,
            object: self)
    }

    func gg_removeTextViewNotificationObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UITextViewTextDidChangeNotification,
            object: self)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UITextViewTextDidBeginEditingNotification,
            object: self)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UITextViewTextDidEndEditingNotification,
            object:self)
    }

    func gg_didReceiveTextViewNotification(notification: NSNotification) {
        self.setNeedsDisplay()
    }

    // pragma mark - Utilities

    func gg_placeholderTextAttributes() -> [String: AnyObject] {
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        paragraphStyle.alignment = self.textAlignment
        
        return [
            NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: self.placeHolderTextColor,
            NSParagraphStyleAttributeName: paragraphStyle ]
    }

}
