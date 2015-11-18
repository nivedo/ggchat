//
//  MessagesCollectionViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewCell: UICollectionViewCell {
   
    
    @IBOutlet weak var cellBottomLabel: MessageLabel!
    @IBOutlet weak var cellTopLabel: MessageLabel!
    @IBOutlet weak var messageBubbleTopLabel: MessageLabel!
    @IBOutlet weak var textView: MessageCellTextView!
    
    @IBOutlet weak var messageBubbleContainerView: UIView!
    @IBOutlet weak var messageBubbleImageView: UIImageView!
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
   
    var avatarViewSize: CGSize?
    var textViewFrameInsets: UIEdgeInsets?
    var tapGestureRecognizer: UITapGestureRecognizer?
    
    var delegate: MessagesCollectionView?
    
    static var ggMessagesCollectionViewCellActions = NSMutableSet()
    
    @IBOutlet weak var messageBubbleContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTopVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewBottomVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewMarginHorizontalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewAvatarHorizontalSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cellTopLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBubbleTopLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellBottomLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var avatarContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarContainerViewHeightConstraint: NSLayoutConstraint!

    class func nib() -> UINib {
        return UINib(nibName: NSStringFromClass(self), bundle: NSBundle(forClass: self))
    }
    
    class func cellReuseIdentifier() -> String {
        return NSStringFromClass(self);
    }
    
    class func mediaCellReuseIdentifier() -> String {
        return "\(NSStringFromClass(self))_GGMedia"
    }

    class func registerMenuAction(action: Selector) {
        self.ggMessagesCollectionViewCellActions.addObject(NSStringFromSelector(action))
    }

    // pragma mark - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.whiteColor()
   
        self.cellTopLabelHeightConstraint.constant = 0.0
        self.messageBubbleTopLabelHeightConstraint.constant = 0.0
        self.cellBottomLabelHeightConstraint.constant = 0.0
        
        self.avatarViewSize = CGSizeZero
        
        self.cellTopLabel.textAlignment = NSTextAlignment.Center
        self.cellTopLabel.font = UIFont.boldSystemFontOfSize(12.0)
        self.cellTopLabel.textColor = UIColor.lightGrayColor()
        
        self.messageBubbleTopLabel.font = UIFont.systemFontOfSize(12.0)
        self.messageBubbleTopLabel.textColor = UIColor.lightGrayColor()
        
        self.cellBottomLabel.font = UIFont.systemFontOfSize(11.0)
        self.cellBottomLabel.textColor = UIColor.lightGrayColor()
        
        let tap = UITapGestureRecognizer(target: self, action: ":gg_handleTapGesture")
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap;
    }
    
    // pragma mark - Collection view cell
    override func prepareForReuse() {
        super.prepareForReuse()
    
        self.cellTopLabel.text = nil
        self.messageBubbleTopLabel.text = nil
        self.cellBottomLabel.text = nil
        
        self.textView.dataDetectorTypes = UIDataDetectorTypes.None
        self.textView.text = nil
        self.textView.attributedText = nil
        
        self.avatarImageView.image = nil
        self.avatarImageView.highlightedImage = nil
    }

    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        print("applyLayoutAttributes()")
        super.applyLayoutAttributes(layoutAttributes)
    
        let customAttributes: MessagesCollectionViewLayoutAttributes = layoutAttributes as! MessagesCollectionViewLayoutAttributes
        
        if (self.textView.font != customAttributes.messageBubbleFont) {
            self.textView.font = customAttributes.messageBubbleFont
        }
        
        if (!UIEdgeInsetsEqualToEdgeInsets(self.textView.textContainerInset, customAttributes.textViewTextContainerInsets!)) {
            self.textView.textContainerInset = customAttributes.textViewTextContainerInsets!
        }
        
        self.textViewFrameInsets = customAttributes.textViewFrameInsets;
        
        self.gg_updateConstraint(self.messageBubbleContainerWidthConstraint,
            withConstant: customAttributes.messageBubbleContainerViewWidth)
        
        self.gg_updateConstraint(self.cellTopLabelHeightConstraint,
            withConstant: customAttributes.cellTopLabelHeight)
        
        self.gg_updateConstraint(self.messageBubbleTopLabelHeightConstraint,
            withConstant: customAttributes.messageBubbleTopLabelHeight)
        
        self.gg_updateConstraint(self.cellBottomLabelHeightConstraint,
            withConstant: customAttributes.cellBottomLabelHeight)
        
        if (self.isKindOfClass(IncomingMessagesCollectionViewCell.self)) {
            self.avatarViewSize = customAttributes.incomingAvatarViewSize
        } else if (self.isKindOfClass(OutgoingMessagesCollectionViewCell.self)) {
            self.avatarViewSize = customAttributes.outgoingAvatarViewSize
        }
    }
    
    override var highlighted: Bool {
        didSet {
            self.messageBubbleImageView.highlighted = self.highlighted;
        }
    }
    
    override var selected: Bool {
        didSet {
            self.messageBubbleImageView.highlighted = self.selected;
        }
    }
    
    //  FIXME: radar 18326340
    //         remove when fixed
    //         hack for Xcode6 / iOS 8 SDK rendering bug that occurs on iOS 7.x
    //         see issue #484
    //         https://github.com/jessesquires/JSQMessagesViewController/issues/484
    //
    override var bounds: CGRect {
        didSet {
            if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                self.contentView.frame = self.bounds;
            }
        }
    }
    
    // pragma mark - Menu actions
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        if (self.dynamicType.ggMessagesCollectionViewCellActions.containsObject(NSStringFromSelector(aSelector))) {
            return true
        }
        
        return super.respondsToSelector(aSelector)
    }
    
    /*
    override func forwardInvocation(anInvocation: NSInvocation) {
        if (self.dynamicType.ggMessagesCollectionViewCellActions.containsObject(NSStringFromSelector(anInvocation.selector))) {
            // __unsafe_unretained id sender;
            var sender
            anInvocation.getArgument(&sender, atIndex:0)
            self.delegate.messagesCollectionViewCell(self, didPerformAction:anInvocation.selector, withSender:sender)
        } else {
            super.forwardInvocation(anInvocation)
        }
    }

    func methodSignatureForSelector(aSelector: Selector) -> NSMethodSignature {
        if (self.dynamicType.ggMessagesCollectionViewCellActions.containsObject(NSStringFromSelector(aSelector))) {
            return NSMethodSignature.signatureWithObjCTypes("v@:@")
        }
        
        return super.methodSignatureForSelector(aSelector)
    }
    */
    
    // pragma mark - Setters
   
    override var backgroundColor: UIColor? {
        didSet (backgroundColor) {
            self.cellTopLabel.backgroundColor = backgroundColor;
            self.messageBubbleTopLabel.backgroundColor = backgroundColor;
            self.cellBottomLabel.backgroundColor = backgroundColor;
            
            self.messageBubbleImageView.backgroundColor = backgroundColor;
            self.avatarImageView.backgroundColor = backgroundColor;
            
            self.messageBubbleContainerView.backgroundColor = backgroundColor;
            self.avatarContainerView.backgroundColor = backgroundColor;
        }
    }
    
    /*
    func setAvatarViewSize(avatarViewSize: CGSize) {
        if (CGSizeEqualToSize(avatarViewSize, self.avatarViewSize)) {
            return;
        }
        
        self.gg_updateConstraint(self.avatarContainerViewWidthConstraint, withConstant:avatarViewSize.width)
        self.gg_updateConstraint(self.avatarContainerViewHeightConstraint, withConstant:avatarViewSize.height)
    }
   
    func setTextViewFrameInsets(textViewFrameInsets: UIEdgeInsets) {
        if (UIEdgeInsetsEqualToEdgeInsets(textViewFrameInsets, self.textViewFrameInsets)) {
            return
        }
        
        self.gg_updateConstraint(self.textViewTopVerticalSpaceConstraint, withConstant:textViewFrameInsets.top)
        self.gg_updateConstraint(self.textViewBottomVerticalSpaceConstraint, withConstant:textViewFrameInsets.bottom)
        self.gg_updateConstraint(self.textViewAvatarHorizontalSpaceConstraint, withConstant:textViewFrameInsets.right)
        self.gg_updateConstraint(self.textViewMarginHorizontalSpaceConstraint, withConstant:textViewFrameInsets.left)
    }
    */
    
    var mediaView: UIView {
        set (mediaView) {
            self.messageBubbleImageView.removeFromSuperview()
            self.textView.removeFromSuperview()
            
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            mediaView.frame = self.messageBubbleContainerView.bounds
            
            self.messageBubbleContainerView.addSubview(mediaView)
            self.messageBubbleContainerView.gg_pinAllEdgesOfSubview(mediaView)
            self.mediaView = mediaView;
            
            //  because of cell re-use (and caching media views, if using built-in library media item)
            //  we may have dequeued a cell with a media view and add this one on top
            //  thus, remove any additional subviews hidden behind the new media view
            dispatch_async(dispatch_get_main_queue()) {
                for (var i = 0; i < self.messageBubbleContainerView.subviews.count; i++) {
                    if (self.messageBubbleContainerView.subviews[i] != self.mediaView) {
                        self.messageBubbleContainerView.subviews[i].removeFromSuperview()
                    }
                }
            }
        }
        get {
            return self.mediaView
        }
    }
    
    // pragma mark - Getters
    /*
    func avatarViewSize() -> CGSize {
        return CGSizeMake(
            self.avatarContainerViewWidthConstraint.constant,
            self.avatarContainerViewHeightConstraint.constant)
    }
    
    func textViewFrameInsets() -> UIEdgeInsets {
        return UIEdgeInsetsMake(
            self.textViewTopVerticalSpaceConstraint.constant,
            self.textViewMarginHorizontalSpaceConstraint.constant,
            self.textViewBottomVerticalSpaceConstraint.constant,
            self.textViewAvatarHorizontalSpaceConstraint.constant)
    }
    */
    
    // pragma mark - Utilities
    
    func gg_updateConstraint(constraint: NSLayoutConstraint, withConstant constant: CGFloat) {
        if (constraint.constant == constant) {
            return;
        }
    
        constraint.constant = constant;
    }
    
    // pragma mark - Gesture recognizers
    /*
    func gg_handleTapGesture(tap: UITapGestureRecognizer) {
        let touchPt: CGPoint = tap.locationInView(self)
        
        if (CGRectContainsPoint(self.avatarContainerView.frame, touchPt)) {
            self.delegate.messagesCollectionViewCellDidTapAvatar(self)
        }
        else if (CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt)) {
            self.delegate.messagesCollectionViewCellDidTapMessageBubble(self)
        }
        else {
            self.delegate.messagesCollectionViewCellDidTapCell(self, atPosition:touchPt)
        }
    }
    */
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let touchPt: CGPoint = touch.locationInView(self)
    
        if (gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer)) {
            return CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt);
        }
        
        return true;
    }
}
