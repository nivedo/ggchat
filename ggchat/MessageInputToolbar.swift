//
//  MessageInputToolbar.swift
//  ggchat
//
//  Created by Gary Chang on 11/15/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageInputToolbar: UIToolbar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    // static void * kMessagesInputToolbarKeyValueObservingContext = &kMessagesInputToolbarKeyValueObservingContext



    // pragma mark - Initialization
/*
    override func awakeFromNib() {
        super.awakeFromNib()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.gg_isObserving = false
        self.sendButtonOnRight = true

        self.preferredDefaultHeight = 44.0
        self.maximumHeight = NSNotFound

        MessagesToolbarContentView *toolbarContentView = [self loadToolbarContentView]
        toolbarContentView.frame = self.frame
        [self addSubview:toolbarContentView]
        [self gg_pinAllEdgesOfSubview:toolbarContentView]
        [self setNeedsUpdateConstraints]
        _contentView = toolbarContentView

        [self gg_addObservers]

        self.contentView.leftBarButtonItem = [MessagesToolbarButtonFactory defaultAccessoryButtonItem]
        self.contentView.rightBarButtonItem = [MessagesToolbarButtonFactory defaultSendButtonItem]

        [self toggleSendButtonEnabled]
    }

- (MessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[MessagesInputToolbar class]] loadNibNamed:NSStringFromClass([MessagesToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil]
    return nibViews.firstObject
}

- (void)dealloc
{
    [self gg_removeObservers]
    _contentView = nil
}

#pragma mark - Setters

- (void)setPreferredDefaultHeight:(CGFloat)preferredDefaultHeight
{
    NSParameterAssert(preferredDefaultHeight > 0.0f)
    _preferredDefaultHeight = preferredDefaultHeight
}

#pragma mark - Actions

- (void)gg_leftBarButtonPressed:(UIButton *)sender
{
    [self.delegate messagesInputToolbar:self didPressLeftBarButton:sender]
}

- (void)gg_rightBarButtonPressed:(UIButton *)sender
{
    [self.delegate messagesInputToolbar:self didPressRightBarButton:sender]
}

#pragma mark - Input toolbar

- (void)toggleSendButtonEnabled
{
    BOOL hasText = [self.contentView.textView hasText]

    if (self.sendButtonOnRight) {
        self.contentView.rightBarButtonItem.enabled = hasText
    }
    else {
        self.contentView.leftBarButtonItem.enabled = hasText
    }
}

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

- (void)gg_addObservers
{
    if (self.gg_isObserving) {
        return
    }

    [self.contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                          options:0
                          context:kMessagesInputToolbarKeyValueObservingContext]

    [self.contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                          options:0
                          context:kMessagesInputToolbarKeyValueObservingContext]

    self.gg_isObserving = true
}

- (void)gg_removeObservers
{
    if (!_gg_isObserving) {
        return
    }

    @try {
        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                             context:kMessagesInputToolbarKeyValueObservingContext]

        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                             context:kMessagesInputToolbarKeyValueObservingContext]
    }
    @catch (NSException *__unused exception) { }
    
    _gg_isObserving = false
}
*/
    
}
