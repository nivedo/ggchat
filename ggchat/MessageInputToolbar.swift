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

    /**
     *  Tells the delegate that the toolbar's `leftBarButtonItem` has been pressed.
     *
     *  @param toolbar The object representing the toolbar sending this information.
     *  @param sender  The button that received the touch event.
     */
    func messagesInputToolbar(toolbar: MessageInputToolbar,
           didPressLeftBarButton sender: UIButton)
}

class MessageInputToolbar: UIToolbar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    static let kMessagesInputToolbarKeyValueObservingContext = UnsafeMutablePointer<()>()

    var messageDelegate: MessageInputToolbarDelegate { return self.delegate as! MessageInputToolbarDelegate }
    var gg_isObserving: Bool = false
    var sendButtonOnRight: Bool = true
    var maximumHeight: Int = NSNotFound
    var contentView: MessageToolbarContentView!
    
    // pragma mark - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        self.translatesAutoresizingMaskIntoConstraints = false

        self.maximumHeight = NSNotFound

        /*
        let toolbarContentView: MessageToolbarContentView = self.loadToolbarContentView()
        toolbarContentView.frame = self.frame
        self.addSubview(toolbarContentView)
        self.gg_pinAllEdgesOfSubview(toolbarContentView)
        self.setNeedsUpdateConstraints()
        self.contentView = toolbarContentView

        self.gg_addObservers()

        // self.contentView.leftBarButtonItem = MessageToolbarButtonFactory.defaultAccessoryButtonItem()
        // self.contentView.rightBarButtonItem = MessagesToolbarButtonFactory.defaultSendButtonItem()

        self.toggleSendButtonEnabled()
        */
    }
    
    func loadToolbarContentView() -> MessageToolbarContentView {
        let nibViews: NSArray = NSBundle(forClass: MessageInputToolbar.self).loadNibNamed(
                NSStringFromClass(MessageToolbarContentView.self),
                owner: nil,
                options: nil)
        return nibViews.firstObject as! MessageToolbarContentView
    }


    // pragma mark - Setters

    var preferredDefaultHeight: CGFloat = 44.0 {
        willSet {
            assert(preferredDefaultHeight > 0.0)
        }
    }

    // pragma mark - Actions

    func gg_leftBarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressLeftBarButton: sender)
    }

    func gg_rightBarButtonPressed(sender: UIButton) {
        self.messageDelegate.messagesInputToolbar(self, didPressRightBarButton: sender)
    }

    // pragma mark - Input toolbar

    func toggleSendButtonEnabled() {
        let hasText: Bool = self.contentView.textView.hasText()

        if (self.sendButtonOnRight) {
            self.contentView.rightBarButtonItem!.enabled = hasText
        } else {
            self.contentView.leftBarButtonItem!.enabled = hasText
        }
    }

/*
#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kMessagesInputToolbarKeyValueObservingContext) {
        if (object == self.contentView) {

            if ([keyPath isEqualToString:NSStringFromSelector(@selector(leftBarButtonItem))]) {

                [self.contentView.leftBarButtonItem removeTarget:self
                                                          action:NULL
                                                forControlEvents:UIControlEventTouchUpInside]

                [self.contentView.leftBarButtonItem addTarget:self
                                                       action:@selector(gg_leftBarButtonPressed:)
                                             forControlEvents:UIControlEventTouchUpInside]
            }
            else if ([keyPath isEqualToString:NSStringFromSelector(@selector(rightBarButtonItem))]) {

                [self.contentView.rightBarButtonItem removeTarget:self
                                                           action:NULL
                                                 forControlEvents:UIControlEventTouchUpInside]

                [self.contentView.rightBarButtonItem addTarget:self
                                                        action:@selector(gg_rightBarButtonPressed:)
                                              forControlEvents:UIControlEventTouchUpInside]
            }

            [self toggleSendButtonEnabled]
        }
    }
}
*/
    func gg_addObservers() {
        if (self.gg_isObserving) {
            return
        }

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("leftBarButtonItem")),
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)

        self.contentView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("rightBarButtonItem")),
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
            forKeyPath: NSStringFromSelector(Selector("rightBarButtonItem")),
            context: MessageInputToolbar.kMessagesInputToolbarKeyValueObservingContext)
    
        self.gg_isObserving = false
    }
}
