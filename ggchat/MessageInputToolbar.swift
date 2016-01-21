//
//  MessageInputToolbar.swift
//  ggchat
//
//  Created by Gary Chang on 11/15/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

protocol MessageInputToolbarDelegate: UIToolbarDelegate {

    /**
     *  Tells the delegate that the toolbar's `rightBarButtonItem` has been pressed.
     *
     *  @param toolbar The object representing the toolbar sending this information.
     *  @param sender  The button that received the touch event.
     */
    func messagesInputToolbar(toolbar: MessageInputToolbar,
          didPressRightBarButton sender: UIButton)

    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressRightInnerBarButton sender: UIButton)
    
    /**
     *  Tells the delegate that the toolbar's `leftBarButtonItem` has been pressed.
     *
     *  @param toolbar The object representing the toolbar sending this information.
     *  @param sender  The button that received the touch event.
     */
    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressLeftBarButton sender: UIButton)

    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressLeftInnerBarButton sender: UIButton)

    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressMiddle1BarButton sender: UIButton)
    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressMiddle2BarButton sender: UIButton)
    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressMiddle3BarButton sender: UIButton)
}

class MessageInputToolbar: UIToolbar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    static let kMessagesInputToolbarKeyValueObservingContext = UnsafeMutablePointer<Void>()

    var messageDelegate: MessageInputToolbarDelegate { return self.delegate as! MessageInputToolbarDelegate }
    var gg_isObserving: Bool = false
    var sendButtonOnRight: Bool = true
    var maximumHeight: Int = NSNotFound
    var contentView: MessageToolbarContentView!
    
    // pragma mark - Initialization
    override func awakeFromNib() {
        // print("InputToolbar::awakeFromNib()")
        super.awakeFromNib()
        self.translatesAutoresizingMaskIntoConstraints = false

        self.maximumHeight = NSNotFound
        let toolbarContentView: MessageToolbarContentView = self.loadToolbarContentView()
        // print("done")
        toolbarContentView.frame = self.frame
        self.addSubview(toolbarContentView)
        self.gg_pinAllEdgesOfSubview(toolbarContentView)
        self.setNeedsUpdateConstraints()
        self.contentView = toolbarContentView

        self.gg_addObservers()

        self.contentView.leftBarButtonItem = MessageToolbarButtonFactory.defaultKeyboardButtonItem()
        self.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.defaultAccessoryButtonItem()
        self.contentView.rightBarButtonItem = MessageToolbarButtonFactory.defaultSendButtonItem()

        /*
        var keyboardImage: UIImage? = nil
        if let resource = GGWiki.sharedInstance.getAutocompleteResource() {
            keyboardImage = resource.iconImage
        }
        self.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(keyboardImage)
        */
        self.contentView.rightInnerBarButtonItem = MessageToolbarButtonFactory.defaultEllipsisButtonItem()

        self.toggleSendButtonEnabled()
        
        for (index, resource) in GGWiki.sharedInstance.getKeyboardResources().enumerate() {
            if index == 0 {
                self.contentView.middle1BarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(resource.iconImage)
            } else if index == 1 {
                self.contentView.middle2BarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(resource.iconImage)
            }
        }
    }
    
    deinit {
        self.gg_removeObservers()
    }
    
    func loadToolbarContentView() -> MessageToolbarContentView {
        // print("loadToolbarContentView()")
        let nibName = NSStringFromClass(MessageToolbarContentView.self).componentsSeparatedByString(".").last! as String
        /*
        let nibViews = NSBundle(forClass: MessageInputToolbar.self).loadNibNamed(
                nibName,
                owner: nil,
                options: nil)
        return nibViews[0] as! MessageToolbarContentView
        */
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! MessageToolbarContentView
        return view
    }

    // pragma mark - Setters

    var preferredDefaultHeight: CGFloat = 90.0 {
        willSet {
            assert(preferredDefaultHeight > 0.0)
        }
    }

    // pragma mark - Actions

    func gg_leftBarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressLeftBarButton: sender)
    }
    
    func gg_leftInnerBarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressLeftInnerBarButton: sender)
    }

    func gg_rightInnerBarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressRightInnerBarButton: sender)
    }
    
    func gg_middle1BarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressMiddle1BarButton: sender)
    }
    
    func gg_middle2BarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressMiddle2BarButton: sender)
    }

    func gg_middle3BarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressMiddle3BarButton: sender)
    }

    func gg_rightBarButtonPressed(sender: UIButton) {
        // print("gg_rightBarButtonPressed")
        self.messageDelegate.messagesInputToolbar(self, didPressRightBarButton: sender)
    }

    // pragma mark - Input toolbar

    func toggleSendButtonEnabled() {
        let hasText: Bool = self.contentView.textView.hasText()
        
        if (self.sendButtonOnRight) {
            self.contentView.rightBarButtonItem?.enabled = hasText
        } else {
            self.contentView.leftBarButtonItem?.enabled = hasText
        }
    }

    // pragma mark - Key-value observing
    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
        if (context == MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext) {
            if (object === self.contentView) {
                print(keyPath!)
                if (keyPath! == NSStringFromSelector(Selector("leftBarButtonItem"))) {

                    self.contentView.leftBarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.leftBarButtonItem!.addTarget(self,
                        action: "gg_leftBarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("leftInnerBarButtonItem"))) {

                    self.contentView.leftInnerBarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.leftInnerBarButtonItem!.addTarget(self,
                        action: "gg_leftInnerBarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("rightBarButtonItem"))) {
                    self.contentView.rightBarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.rightBarButtonItem!.addTarget(self,
                        action: "gg_rightBarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("rightInnerBarButtonItem"))) {

                    self.contentView.rightInnerBarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.rightInnerBarButtonItem!.addTarget(self,
                        action: "gg_rightInnerBarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("middle1BarButtonItem"))) {

                    self.contentView.middle1BarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.middle1BarButtonItem!.addTarget(self,
                        action: "gg_middle1BarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("middle2BarButtonItem"))) {

                    self.contentView.middle2BarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.middle2BarButtonItem!.addTarget(self,
                        action: "gg_middle2BarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                else if (keyPath! == NSStringFromSelector(Selector("middle3BarButtonItem"))) {

                    self.contentView.middle3BarButtonItem!.removeTarget(self,
                        action: nil,
                        forControlEvents: UIControlEvents.TouchUpInside)

                    self.contentView.middle3BarButtonItem!.addTarget(self,
                        action: "gg_middle3BarButtonPressed:",
                        forControlEvents: UIControlEvents.TouchUpInside)
                }
                self.toggleSendButtonEnabled()
            }
        }
    }
    
    func gg_addObservers() {
        if (self.gg_isObserving) {
            return
        }
        // print("gg_addObservers()")

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("leftBarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("leftInnerBarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("rightBarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("rightInnerBarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle1BarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle2BarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle3BarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)
        
        self.gg_isObserving = true
    }

    func gg_removeObservers() {
        if (!self.gg_isObserving) {
            return
        }

        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("leftBarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("leftInnerBarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("rightBarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)
    
        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("rightInnerBarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)
    
        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle1BarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle2BarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("middle3BarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.gg_isObserving = false
    }
}
