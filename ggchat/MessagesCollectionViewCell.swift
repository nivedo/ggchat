//
//  MessagesCollectionViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

protocol MessageCollectionViewCellDelegate {

    /**
     *  Tells the delegate that the avatarImageView of the cell has been tapped.
     *
     *  @param cell The cell that received the tap touch event.
     */
    func messagesCollectionViewCellDidTapAvatar(cell: MessagesCollectionViewCell)

    /**
     *  Tells the delegate that the message bubble of the cell has been tapped.
     *
     *  @param cell The cell that received the tap touch event.
     */
    func messagesCollectionViewCellDidTapMessageBubble(cell: MessagesCollectionViewCell)

    /**
     *  Tells the delegate that the cell has been tapped at the point specified by position.
     *
     *  @param cell The cell that received the tap touch event.
     *  @param position The location of the received touch in the cell's coordinate system.
     *
     *  @discussion This method is *only* called if position is *not* within the bounds of the cell's
     *  avatar image view or message bubble image view. In other words, this method is *not* called when the cell's
     *  avatar or message bubble are tapped.
     *
     *  @see `messagesCollectionViewCellDidTapAvatar:`
     *  @see `messagesCollectionViewCellDidTapMessageBubble:`
     */
    func messagesCollectionViewCellDidTapCell(cell: MessagesCollectionViewCell, atPosition position: CGPoint)

    /**
     *  Tells the delegate that an actions has been selected from the menu of this cell.
     *  This method is automatically called for any registered actions.
     *
     *  @param cell The cell that displayed the menu.
     *  @param action The action that has been performed.
     *  @param sender The object that initiated the action.
     *
     *  @see `JSQMessagesCollectionViewCell`
     */
    func messagesCollectionViewCell(cell: MessagesCollectionViewCell,
        didPerformAction action: Selector,
        withSender sender: AnyObject?)
}

class MessagesCollectionViewCell: UICollectionViewCell {
   
    
    @IBOutlet weak var cellBottomLabel: MessageLabel!
    @IBOutlet weak var cellTopLabel: MessageLabel!
    @IBOutlet weak var messageBubbleTopLabel: MessageLabel!
    @IBOutlet var textView: MessageCellTextView!
    
    @IBOutlet weak var messageBubbleContainerView: UIView!
    @IBOutlet var messageBubbleImageView: UIImageView!
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
   
    // var avatarViewSize: CGSize?
    // var textViewFrameInsets: UIEdgeInsets?
    var tapGestureRecognizer: UITapGestureRecognizer?
    
    var delegate: MessageCollectionViewCellDelegate!
    
    static var ggMessagesCollectionViewCellActions = NSMutableSet()
    
    @IBOutlet weak var messageBubbleContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var textViewTopVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var textViewBottomVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var textViewMarginHorizontalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var textViewAvatarHorizontalSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cellTopLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBubbleTopLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellBottomLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var avatarContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarContainerViewHeightConstraint: NSLayoutConstraint!

    class func nib() -> UINib {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return UINib(nibName: nibName, bundle: NSBundle(forClass: self))
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
        self.backgroundColor = GGConfig.backgroundColor // UIColor.whiteColor()
   
        self.cellTopLabelHeightConstraint.constant = 0.0
        self.messageBubbleTopLabelHeightConstraint.constant = 0.0
        self.cellBottomLabelHeightConstraint.constant = 0.0
        
        self.avatarViewSize = CGSizeZero
        
        self.cellTopLabel.textAlignment = NSTextAlignment.Center
        self.cellTopLabel.font = UIFont.boldSystemFontOfSize(12.0)
        self.cellTopLabel.textColor = GGConfig.cellTopLabelTextColor
        
        self.messageBubbleTopLabel.font = UIFont.systemFontOfSize(12.0)
        self.messageBubbleTopLabel.textColor = GGConfig.bubbleTopLabelTextColor
        
        self.cellBottomLabel.font = UIFont.systemFontOfSize(11.0)
        self.cellBottomLabel.textColor = GGConfig.cellBottomLabelTextColor
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("gg_handleTapGesture:"))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap;
    }
    
    // pragma mark - Collection view cell
    override func prepareForReuse() {
        self.cellTopLabel.text = nil
        self.messageBubbleTopLabel.text = nil
        self.cellBottomLabel.text = nil
        
        self.textView.dataDetectorTypes = UIDataDetectorTypes.None
        self.textView.text = nil
        self.textView.attributedText = nil
        
        self.avatarImageView.image = nil
        self.avatarImageView.highlightedImage = nil

        super.prepareForReuse()
    }

    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        // print("applyLayoutAttributes()")
        super.applyLayoutAttributes(layoutAttributes)
    
        let customAttributes: MessagesCollectionViewLayoutAttributes = layoutAttributes as! MessagesCollectionViewLayoutAttributes
        
        if (self.textView.font != customAttributes.messageBubbleFont) {
            self.textView.font = customAttributes.messageBubbleFont
        }
        
        if (!UIEdgeInsetsEqualToEdgeInsets(self.textView.textContainerInset, customAttributes.textViewTextContainerInsets!)) {
            self.textView.textContainerInset = customAttributes.textViewTextContainerInsets!
        }
        
        // print(customAttributes.textViewFrameInsets!)
        self.textViewFrameInsets = customAttributes.textViewFrameInsets!
        // print(self.textViewAvatarHorizontalSpaceConstraint.constant)
        
        self.messageBubbleContainerWidthConstraint.constant = customAttributes.messageBubbleContainerViewWidth
        
        self.cellTopLabelHeightConstraint.constant = customAttributes.cellTopLabelHeight
        self.messageBubbleTopLabelHeightConstraint.constant = customAttributes.messageBubbleTopLabelHeight
        self.cellBottomLabelHeightConstraint.constant = customAttributes.cellBottomLabelHeight
        
        if (self.isKindOfClass(IncomingMessagesCollectionViewCell.self)) {
            self.avatarViewSize = customAttributes.incomingAvatarViewSize
        } else if (self.isKindOfClass(OutgoingMessagesCollectionViewCell.self)) {
            self.avatarViewSize = customAttributes.outgoingAvatarViewSize
        }
    }
    
    override var highlighted: Bool {
        didSet {
            self.messageBubbleImageView.highlighted = self.highlighted
        }
    }
    
    override var selected: Bool {
        didSet {
            self.messageBubbleImageView.highlighted = self.selected
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
    
    // pragma mark - Getters
    var textViewFrameInsets: UIEdgeInsets {
        get {
            return UIEdgeInsetsMake(
                self.textViewTopVerticalSpaceConstraint.constant,
                self.textViewMarginHorizontalSpaceConstraint.constant,
                self.textViewBottomVerticalSpaceConstraint.constant,
                self.textViewAvatarHorizontalSpaceConstraint.constant)
        }
        set (insets) {
            // print("set textViewFrameInsets")
            self.textViewTopVerticalSpaceConstraint.constant = insets.top
            self.textViewBottomVerticalSpaceConstraint.constant = insets.bottom
            self.textViewAvatarHorizontalSpaceConstraint.constant = insets.right
            self.textViewMarginHorizontalSpaceConstraint.constant = insets.left
            
            // print("\(insets.right) --> \(self.textViewAvatarHorizontalSpaceConstraint.constant)")
        }
    }
    
    var avatarViewSize: CGSize {
        get {
            return CGSizeMake(
                self.avatarContainerViewWidthConstraint.constant,
                self.avatarContainerViewHeightConstraint.constant)
        }
        set {
            self.avatarContainerViewWidthConstraint.constant = newValue.width
            self.avatarContainerViewHeightConstraint.constant = newValue.height
        }
    }
    
    var mediaView: UIView? {
        willSet {
            self.messageBubbleImageView.removeFromSuperview()
            self.textView.removeFromSuperview()
            // self.messageBubbleImageView.hidden = true
            // self.textView.hidden = true
            
            newValue!.translatesAutoresizingMaskIntoConstraints = false
            newValue!.frame = self.messageBubbleContainerView.bounds
            
            self.messageBubbleContainerView.addSubview(newValue!)
            self.messageBubbleContainerView.gg_pinAllEdgesOfSubview(newValue!)
        }
        didSet {
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
    }
    
    // pragma mark - Utilities
    /*
    func gg_updateConstraint(constraint: NSLayoutConstraint, withConstant constant: CGFloat) {
        if (constraint.constant == constant) {
            return;
        }
    
        constraint.constant = constant;
    }
    */
    
    // pragma mark - Gesture recognizers
    func gg_handleTapGesture(tap: UITapGestureRecognizer) {
        print("ViewCell::gg_handleTapGesture()")
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

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let touchPt: CGPoint = touch.locationInView(self)
    
        if (gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer)) {
            return CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt);
        }
        
        return true;
    }
}
