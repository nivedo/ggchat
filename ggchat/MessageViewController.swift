//
//  MessageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/16/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MessageViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    MessageInputToolbarDelegate,
    MessageKeyboardControllerDelegate,
    UITextViewDelegate {
    
    static let kMessagesKeyValueObservingContext = UnsafeMutablePointer<Void>()
    
    //////////////////////////////////////////////////////////////////////////////////
    // Properties
    //////////////////////////////////////////////////////////////////////////////////
    
    // @IBOutlet weak var messageCollectionView: MessagesCollectionView!
    @IBOutlet weak var messageCollectionView: MessagesCollectionView!
    @IBOutlet weak var inputToolbar: MessageInputToolbar!
    var keyboardController: MessageKeyboardController?
    
    var automaticallyScrollsToMostRecentMessage: Bool = true
    var outgoingCellIdentifier: String = OutgoingMessagesCollectionViewCell.cellReuseIdentifier()
    var outgoingMediaCellIdentifier: String = OutgoingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    var incomingCellIdentifier: String = IncomingMessagesCollectionViewCell.cellReuseIdentifier()
    var incomingMediaCellIdentifier: String = IncomingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    
    var gg_isObserving: Bool = false
    var currentInteractivePopGestureRecognizer: UIGestureRecognizer?
    var snapshotView: UIView?
    
    // pragma mark - Setters
    
    var showTypingIndicator: Bool = true {
        didSet {
            self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
            self.messageCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    var showLoadEarlierMessagesHeader: Bool = true {
        didSet {
            /*
            if (self.showLoadEarlierMessagesHeader == newShowLoadEarlierMessagesHeader) {
                return
            }
            */

            self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
            self.messageCollectionView.collectionViewLayout.invalidateLayout()
            self.messageCollectionView.reloadData()
        }
    }

    var topContentAdditionalInset: CGFloat = 0.0 {
        didSet {
            self.gg_updateCollectionViewInsets()
        }
    }
    
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarBottomLayoutGuide: NSLayoutConstraint!
    
    var senderId: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
    var senderDisplayName: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
    let incomingBubble = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(
        UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(
        UIColor.lightGrayColor())
    var outgoingBubbleImage: MessageBubbleImage = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(GGConfig.outgoingBubbleColor)
    var incomingBubbleImage: MessageBubbleImage = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(GGConfig.incomingBubbleColor)
    var selectedIndexPathForMenu: NSIndexPath?
    
    ///////////////////////////////////////////////////////////////////////////////
    
    func setup() {
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.toolbarHeightConstraint.constant = self.inputToolbar.preferredDefaultHeight
        
        self.messageCollectionView.dataSource = self;
        self.messageCollectionView.delegate = self;
        
        self.inputToolbar.delegate = self
        self.inputToolbar.contentView.textView.placeHolder = NSBundle.gg_localizedStringForKey("new_message")
        self.inputToolbar.contentView.textView.delegate = self
        
        // NOTE: let this behavior be opt-in for now
        MessagesCollectionViewCell.registerMenuAction(Selector("delete:"))
        
        self.gg_updateCollectionViewInsets()
        
        // Don't set keyboardController if client creates custom content view via -loadToolbarContentView
        /*
        if (self.inputToolbar.contentView.textView != nil) {
            self.keyboardController = MessageKeyboardController(
                textView: self.inputToolbar.contentView.textView,
                contextView: self.view,
                panGestureRecognizer: self.messageCollectionView.panGestureRecognizer,
                delegate: self)
        }
        */
    }
    
    /////////////////////////////////////////////////////////////////////////////
    // UICollectionViewController methods
    /////////////////////////////////////////////////////////////////////////////
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("MessageViewController::awakeFromNib()")
    }
    
    override func viewDidLoad() {
        print("MessageViewController::viewDidLoad()")
        super.viewDidLoad()
        
        // Load outlets to self
        let nib = UINib(nibName: "MessageViewController", bundle: NSBundle.mainBundle())
        nib.instantiateWithOwner(self, options: nil)

        self.gg_registerForNotifications(true)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Register cell classes
        
        /*
        self.messageCollectionView.registerClass(
            MessagesCollectionViewCell.self,
            forCellWithReuseIdentifier: reuseIdentifier)
        */
        
        // Do any additional setup after loading the view.
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    ///////////////////////////////////////////////////////////////////////////////
    // MARK: UICollectionViewDataSource
    ///////////////////////////////////////////////////////////////////////////////

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        // print("MVC::numberOfSectionsInCollectionView")
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // print("MVC::numberOfItemsInSection: \(GGModelData.sharedInstance.messages.count)")
        return GGModelData.sharedInstance.messages.count
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    ///////////////////////////////////////////////////////////////////////////////
    // MARK - Data Source
    ///////////////////////////////////////////////////////////////////////////////

    func collectionView(collectionView: MessagesCollectionView,
        messageDataForItemAtIndexPath indexPath: NSIndexPath) -> Message {
        // print("MVC::messageDataForItemAtIndexPath")
        let data = GGModelData.sharedInstance.messages[indexPath.row]
        return data
    }
    
    func collectionView(collectionView: MessagesCollectionView,
        didDeleteMessageAtIndexPath indexPath: NSIndexPath) {
        print("MVC::didDeleteMessageAtIndexPath")
        GGModelData.sharedInstance.messages.removeAtIndex(indexPath.row)
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    
    func collectionView(collectionView: MessagesCollectionView, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageBubbleImage {
        // print("MVC::messageBubbleImageDataForItemAtIndexPath")
        /**
        *  You may return nil here if you do not want bubbles.
        *  In this case, you should set the background color of your collection view cell's textView.
        *
        *  Otherwise, return your previously created bubble image data objects.
        */
        // let message: Message = self.messages[indexPath.item]
        let message: Message = GGModelData.sharedInstance.messages[indexPath.item]
    
        if (message.senderId == self.senderId) {
            return self.outgoingBubbleImage
        }
        
        return self.incomingBubbleImage
    }
    
    func collectionView(collectionView: MessagesCollectionView, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        // print("MVC::avatarImageDataForItemAtIndexPath")
        /**
        *  Return `nil` here if you do not want avatars.
        *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
        *
        *  self.messageCollectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        *  self.messageCollectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        *
        *  It is possible to have only outgoing avatars or only incoming avatars, too.
        */
        
        /**
        *  Return your previously created avatar image data objects.
        *
        *  Note: these the avatars will be sized according to these values:
        *
        *  self.messageCollectionView.collectionViewLayout.incomingAvatarViewSize
        *  self.messageCollectionView.collectionViewLayout.outgoingAvatarViewSize
        *
        *  Override the defaults in `viewDidLoad`
        */
        // let message: Message = self.messages[indexPath.item]
        let message: Message = GGModelData.sharedInstance.messages[indexPath.item]
        /*
        let defaults = NSUserDefaults.standardUserDefaults()
        if (message.senderId == self.senderId) {
            if (!defaults.boolForKey("outgoingAvatarSetting")) {
                return nil;
            }
        }
        else {
            if (!defaults.boolForKey("incomingAvatarSetting")) {
                return nil;
            }
        }
        */
        return GGModelData.sharedInstance.avatars[message.senderId];
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        // print("MVC::attributedTextForCellTopLabelAtIndexPath")
        /**
        *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
        *  The other label text delegate methods should follow a similar pattern.
        *
        *  Show a timestamp for every 3rd message
        */
        if (indexPath.item % 3 == 0) {
            // let message: Message = self.messages[indexPath.item]
            let message: Message = GGModelData.sharedInstance.messages[indexPath.item]
            return MessageTimestampFormatter.sharedInstance.attributedTimestampForDate(message.date)
        }
        return nil;
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        // print("MVC::attributedTextForMessageBubbleTopLabelAtIndexPath")
        // let message: Message = self.messages[indexPath.item]
        let message: Message = GGModelData.sharedInstance.messages[indexPath.item]
        
        /**
        *  iOS7-style sender name labels
        */
        if (message.senderId == self.senderId) {
            return nil
        }
        
        if (indexPath.item - 1 > 0) {
            // let previousMessage: Message = self.messages[indexPath.item - 1]
            let previousMessage: Message = GGModelData.sharedInstance.messages[indexPath.item - 1]
            if (previousMessage.senderId == message.senderId) {
                return nil
            }
        }
    
        /**
        *  Don't specify attributes to use the defaults.
        */
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        // print("MVC::attributedTextForCellBottomLabelAtIndexPath")
        return nil;
    }

    // pragma mark - View lifecycle
    override func viewWillAppear(animated: Bool) {
        print("MessageViewController::viewWillAppear()")
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        self.messageCollectionView.collectionViewLayout.invalidateLayout()

        if (self.automaticallyScrollsToMostRecentMessage) {
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollToBottomAnimated(false)
                self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
            }
        }

        self.gg_updateKeyboardTriggerPoint()
    }

    override func viewDidAppear(animated: Bool) {
        print("MessageViewController::viewDidAppear()")
        super.viewDidAppear(animated)
        self.gg_addObservers()
        self.gg_addActionToInteractivePopGestureRecognizer(true)
        // self.keyboardController.beginListeningForKeyboard()

        if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
            self.snapshotView!.removeFromSuperview()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.messageCollectionView.messageCollectionViewLayout.springinessEnabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.gg_addActionToInteractivePopGestureRecognizer(false)
        self.gg_removeObservers()
        // self.keyboardController.endListeningForKeyboard()
    }

    // pragma mark - View rotation
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            return UIInterfaceOrientationMask.AllButUpsideDown;
        }
        return UIInterfaceOrientationMask.All;
    }

    override func willRotateToInterfaceOrientation(
        toInterfaceOrientation: UIInterfaceOrientation,
        duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration:duration)
        self.messageCollectionView.messageCollectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        if (self.showTypingIndicator) {
            self.showTypingIndicator = false
            self.showTypingIndicator = true
            self.messageCollectionView.reloadData()
        }
    }

    // pragma mark - Messages view controller

    func didPressSendButton(
        button: UIButton,
        withMessageText text: String,
        senderId: String,
        senderDisplayName: String,
        date: NSDate) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressSendButton")
    }

    func didPressAccessoryButton(sender: UIButton) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressAccessoryButton")
    }

    func finishSendingMessage() {
        self.finishSendingMessageAnimated(true)
    }

    func finishSendingMessageAnimated(animated: Bool) {
        let textView: UITextView = self.inputToolbar.contentView.textView
        textView.text = nil
        textView.undoManager!.removeAllActions()

        self.inputToolbar.toggleSendButtonEnabled()

        NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object:textView)
        
        self.messageCollectionView.messageCollectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        self.messageCollectionView.reloadData()

        if (self.automaticallyScrollsToMostRecentMessage) {
            self.scrollToBottomAnimated(animated)
        }
    }

    func finishReceivingMessage() {
        self.finishReceivingMessageAnimated(true)
    }

    func finishReceivingMessageAnimated(animated: Bool) {
        self.showTypingIndicator = false

        self.messageCollectionView.messageCollectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        self.messageCollectionView.reloadData()

        if (self.automaticallyScrollsToMostRecentMessage && !self.gg_isMenuVisible()) {
            self.scrollToBottomAnimated(animated)
        }
    }

    func scrollToBottomAnimated(animated: Bool) {
        if (self.messageCollectionView.numberOfSections() == 0) {
            return
        }

        let items = self.messageCollectionView.numberOfItemsInSection(0)

        if (items == 0) {
            return;
        }
        
        let collectionViewContentHeight: CGFloat = self.messageCollectionView.messageCollectionViewLayout.collectionViewContentSize().height
        let isContentTooSmall: Bool = (collectionViewContentHeight < CGRectGetHeight(self.messageCollectionView.bounds))

        if (isContentTooSmall) {
            //  workaround for the first few messages not scrolling
            //  when the collection view content size is too small, `scrollToItemAtIndexPath:` doesn't work properly
            //  this seems to be a UIKit bug, see #256 on GitHub
            self.messageCollectionView.scrollRectToVisible(
                CGRectMake(0.0, collectionViewContentHeight - 1.0, 1.0, 1.0),
                animated:animated)
            return
        }

        //  workaround for really long messages not scrolling
        //  if last message is too long, use scroll position bottom for better appearance, else use top
        //  possibly a UIKit bug, see #480 on GitHub
        let finalRow: Int = max(0, self.messageCollectionView.numberOfItemsInSection(0) - 1)
        let finalIndexPath: NSIndexPath = NSIndexPath(forItem: finalRow, inSection: 0)
        let finalCellSize: CGSize = self.messageCollectionView.messageCollectionViewLayout.sizeForItemAtIndexPath(finalIndexPath)

        let maxHeightForVisibleMessage: CGFloat = CGRectGetHeight(self.messageCollectionView.bounds) - self.messageCollectionView.contentInset.top - CGRectGetHeight(self.inputToolbar.bounds)

        let scrollPosition: UICollectionViewScrollPosition = (finalCellSize.height > maxHeightForVisibleMessage) ? UICollectionViewScrollPosition.Bottom : UICollectionViewScrollPosition.Top

        self.messageCollectionView.scrollToItemAtIndexPath(finalIndexPath,
            atScrollPosition: scrollPosition,
            animated: animated)
    }

    // pragma mark - Collection view data source

    func collectionView(
        uiCollectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // print("MVC::cellForItemAtIndexPath")
        let collectionView: MessagesCollectionView = uiCollectionView as! MessagesCollectionView
        let messageItem: Message = self.messageCollectionView.messageDelegate.collectionView(collectionView, messageDataForItemAtIndexPath:indexPath)
        let messageSenderId: String = messageItem.senderId

        let isOutgoingMessage: Bool = messageSenderId == self.senderId
        let isMediaMessage: Bool = messageItem.isMediaMessage

        var cellIdentifier: String
        if (isMediaMessage) {
            cellIdentifier = isOutgoingMessage ? self.outgoingMediaCellIdentifier : self.incomingMediaCellIdentifier
        } else {
            cellIdentifier = isOutgoingMessage ? self.outgoingCellIdentifier : self.incomingCellIdentifier
        }

        // print(cellIdentifier)
        let cell: MessagesCollectionViewCell = messageCollectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath:indexPath) as! MessagesCollectionViewCell
        cell.delegate = collectionView

        if (!isMediaMessage) {
            cell.textView.text = messageItem.text

            if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                //  workaround for iOS 7 textView data detectors bug
                cell.textView.text = nil
                cell.textView.attributedText = NSAttributedString(
                    string: messageItem.text!,
                    attributes: [ NSFontAttributeName : messageCollectionView.messageCollectionViewLayout.messageBubbleFont ])
            }


            let bubbleImageDataSource: MessageBubbleImage = messageCollectionView.messageDataSource.collectionView(collectionView, messageBubbleImageDataForItemAtIndexPath:indexPath)
            cell.messageBubbleImageView.image = bubbleImageDataSource.messageBubbleImage
            cell.messageBubbleImageView.highlightedImage = bubbleImageDataSource.messageBubbleHighlightedImage
        } else {
            let messageMedia: MessageMediaData = messageItem.media!
            cell.mediaView = (messageMedia.mediaView != nil ? messageMedia.mediaView : messageMedia.mediaPlaceholderView)!
        }
        
        // This is a HACK, should be in init of cell
        if (isOutgoingMessage) {
            cell.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right
            cell.cellBottomLabel.textAlignment = NSTextAlignment.Right
            cell.textView.textColor = GGConfig.outgoingTextColor
        } else {
            cell.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left
            cell.cellBottomLabel.textAlignment = NSTextAlignment.Left
            cell.textView.textColor = GGConfig.incomingTextColor
        }

        var needsAvatar: Bool = true
        if (isOutgoingMessage && CGSizeEqualToSize(messageCollectionView.messageCollectionViewLayout.outgoingAvatarViewSize, CGSizeZero)) {
            needsAvatar = false
        } else if (!isOutgoingMessage && CGSizeEqualToSize(messageCollectionView.messageCollectionViewLayout.incomingAvatarViewSize, CGSizeZero)) {
            needsAvatar = false
        }

        var avatarImageDataSource: MessageAvatarImage? = nil
        if (needsAvatar) {
            avatarImageDataSource = messageCollectionView.messageDataSource.collectionView(
                    collectionView,
                    avatarImageDataForItemAtIndexPath: indexPath)
            // print("avatar: \(avatarImageDataSource)")
            if (avatarImageDataSource != nil) {
                let avatarImage: UIImage? = avatarImageDataSource!.avatarImage
                if (avatarImage == nil) {
                    cell.avatarImageView.image = avatarImageDataSource!.avatarPlaceholderImage
                    cell.avatarImageView.highlightedImage = nil
                } else {
                    cell.avatarImageView.image = avatarImage
                    cell.avatarImageView.highlightedImage = avatarImageDataSource!.avatarHighlightedImage
                }
            }
        }

        cell.cellTopLabel.attributedText = messageCollectionView.messageDataSource.collectionView(collectionView, attributedTextForCellTopLabelAtIndexPath: indexPath)
        cell.messageBubbleTopLabel.attributedText = messageCollectionView.messageDataSource.collectionView(collectionView, attributedTextForMessageBubbleTopLabelAtIndexPath: indexPath)
        cell.cellBottomLabel.attributedText = messageCollectionView.messageDataSource.collectionView(collectionView, attributedTextForCellBottomLabelAtIndexPath:indexPath)

        let bubbleTopLabelInset: CGFloat = (avatarImageDataSource != nil) ? 60.0 : 15.0

        if (isOutgoingMessage) {
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, bubbleTopLabelInset)
        } else {
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0.0, bubbleTopLabelInset, 0.0, 0.0)
        }

        cell.textView.dataDetectorTypes = UIDataDetectorTypes.All

        cell.backgroundColor = UIColor.clearColor()
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        cell.layer.shouldRasterize = true

        return cell
    }
   
    ///////////////////////////////////////////////////////////////////////////////
    // UICollectionViewDataSource
    ///////////////////////////////////////////////////////////////////////////////
   
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        print("MVC::viewForSupplementaryElementOfKind, kind: \(kind)")
        if (self.showTypingIndicator && kind == UICollectionElementKindSectionFooter) {
            return messageCollectionView.dequeueTypingIndicatorFooterViewForIndexPath(indexPath)
        } else if (self.showLoadEarlierMessagesHeader && kind == UICollectionElementKindSectionHeader) {
            return messageCollectionView.dequeueLoadEarlierMessagesViewHeaderForIndexPath(indexPath)
        }
        return messageCollectionView.dequeueReusableCellWithReuseIdentifier(kind, forIndexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int) -> CGSize {
        if (!self.showTypingIndicator) {
            return CGSizeZero
        }

        let messageCollectionViewLayout = collectionViewLayout as! MessagesCollectionViewFlowLayout
        return CGSizeMake(messageCollectionViewLayout.itemWidth, MessageTypingIndicatorFooterView.kMessagesTypingIndicatorFooterViewHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int) -> CGSize {
        if (!self.showLoadEarlierMessagesHeader) {
            return CGSizeZero
        }
        
        let messageCollectionViewLayout = collectionViewLayout as! MessagesCollectionViewFlowLayout
        return CGSizeMake(messageCollectionViewLayout.itemWidth,
            MessageLoadEarlierHeaderView.kMessagesLoadEarlierHeaderViewHeight)
    }

    // pragma mark - Collection view delegate

    func collectionView(
        uiCollectionView: UICollectionView,
        shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        print("MVC::shouldShowMenuForItemIndexPath:")
        let collectionView: MessagesCollectionView = uiCollectionView as! MessagesCollectionView
        //  disable menu for media messages
        let messageItem: Message = messageCollectionView.messageDataSource.collectionView(collectionView, messageDataForItemAtIndexPath:indexPath)
        if (messageItem.isMediaMessage) {
            return false
        }

        self.selectedIndexPathForMenu = indexPath

        //  textviews are selectable to allow data detectors
        //  however, this allows the 'copy, define, select' UIMenuController to show
        //  which conflicts with the collection view's UIMenuController
        //  temporarily disable 'selectable' to prevent this issue
        let selectedCell: MessagesCollectionViewCell = messageCollectionView.cellForItemAtIndexPath(indexPath) as! MessagesCollectionViewCell
        selectedCell.textView.selectable = false

        return true
    }

    func collectionView(collectionView: UICollectionView,
        canPerformAction action: Selector,
        forItemAtIndexPath indexPath: NSIndexPath,
        withSender sender: AnyObject?) -> Bool {
        if (action == Selector("copy:") || action == Selector("delete:")) {
            return true
        }

        return false
    }

    func collectionView(uiCollectionView: UICollectionView,
        performAction action: Selector,
        forItemAtIndexPath indexPath: NSIndexPath,
        withSender sender: AnyObject?) {
        print("MVC::performAction:")
        let collectionView: MessagesCollectionView = uiCollectionView as! MessagesCollectionView
        if (action == Selector("copy:")) {
            let messageData: Message = messageCollectionView.messageDataSource.collectionView(
                collectionView,
                messageDataForItemAtIndexPath:indexPath)
            UIPasteboard.generalPasteboard().string = messageData.text
        } else if (action == Selector("delete:")) {
            messageCollectionView.messageDataSource.collectionView(collectionView,
                didDeleteMessageAtIndexPath:indexPath)

            messageCollectionView.deleteItemsAtIndexPaths([indexPath])
            messageCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // MessageInputToolbarDelegate methods
    //////////////////////////////////////////////////////////////////////////////////

    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressLeftBarButton sender: UIButton) {
        print("MVC::didPressLeftBarButton")
        if (toolbar.sendButtonOnRight) {
            self.didPressAccessoryButton(sender)
        } else {
            self.didPressSendButton(sender,
                withMessageText: self.gg_currentlyComposedMessageText(),
                senderId: self.senderId,
                senderDisplayName: self.senderDisplayName,
                date: NSDate())
        }
    }

    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressRightBarButton sender: UIButton) {
        print("MVC::didPressRightBarButton")
        if (toolbar.sendButtonOnRight) {
            self.didPressSendButton(sender,
                withMessageText: self.gg_currentlyComposedMessageText(),
                senderId: self.senderId,
                senderDisplayName: self.senderDisplayName,
                date: NSDate())
        } else {
            self.didPressAccessoryButton(sender)
        }
    }

    func gg_currentlyComposedMessageText() -> String {
        //  auto-accept any auto-correct suggestions
        self.inputToolbar.contentView.textView.inputDelegate!.selectionWillChange(self.inputToolbar.contentView.textView)
        
        self.inputToolbar.contentView.textView.inputDelegate!.selectionDidChange(self.inputToolbar.contentView.textView)

        return self.inputToolbar.contentView.textView.text.gg_stringByTrimingWhitespace()
    }

    //////////////////////////////////////////////////////////////////////////////////
    // UITextViewDelegate methods
    //////////////////////////////////////////////////////////////////////////////////

    func textViewDidBeginEditing(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }

        textView.becomeFirstResponder()

        if (self.automaticallyScrollsToMostRecentMessage) {
            self.scrollToBottomAnimated(true)
        }
    }

    func textViewDidChange(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }

        self.inputToolbar.toggleSendButtonEnabled()
    }

    func textViewDidEndEditing(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }

        textView.resignFirstResponder()
    }

    // pragma mark - Notifications

    func gg_handleDidChangeStatusBarFrameNotification(notification: NSNotification) {
        /*
        if (self.keyboardController.keyboardIsVisible) {
            self.gg_setToolbarBottomLayoutGuideConstant(CGRectGetHeight(self.keyboardController.currentKeyboardFrame))
        }
        */
    }

    func gg_didReceiveMenuWillShowNotification(notification: NSNotification) {
        if (self.selectedIndexPathForMenu == nil) {
            return
        }

        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIMenuControllerWillShowMenuNotification,
            object:nil)

        let menu: UIMenuController = notification.object! as! UIMenuController
        menu.setMenuVisible(false, animated: false)

        let selectedCell: MessagesCollectionViewCell = self.messageCollectionView.cellForItemAtIndexPath(self.selectedIndexPathForMenu!) as! MessagesCollectionViewCell
        let selectedCellMessageBubbleFrame: CGRect = selectedCell.convertRect(selectedCell.messageBubbleContainerView.frame, toView:self.view)

        menu.setTargetRect(selectedCellMessageBubbleFrame, inView: self.view)
        menu.setMenuVisible(true, animated: true)

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("gg_didReceiveMenuWillShowNotification:"),
            name: UIMenuControllerWillShowMenuNotification,
            object: nil)
    }

    func gg_didReceiveMenuWillHideNotification(notification: NSNotification) {
        if (self.selectedIndexPathForMenu == nil) {
            return
        }

        //  per comment above in 'shouldShowMenuForItemAtIndexPath:'
        //  re-enable 'selectable', thus re-enabling data detectors if present
        let selectedCell: MessagesCollectionViewCell = self.messageCollectionView.cellForItemAtIndexPath(self.selectedIndexPathForMenu!) as! MessagesCollectionViewCell
        selectedCell.textView.selectable = true
        self.selectedIndexPathForMenu = nil
    }

    // pragma mark - Key-value observing
    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
        print("======================================== 0")
        if (context == MessageViewController.kMessagesKeyValueObservingContext) {
            print("======================================== 1")
            if (object === self.inputToolbar.contentView.textView
                && keyPath! == NSStringFromSelector(Selector("contentSize"))) {
                print("======================================== 2")
                let oldContentSize: CGSize = change![NSKeyValueChangeOldKey]!.CGSizeValue()
                let newContentSize: CGSize = change![NSKeyValueChangeNewKey]!.CGSizeValue()

                let dy: CGFloat = newContentSize.height - oldContentSize.height

                self.gg_adjustInputToolbarForComposerTextViewContentSizeChange(dy)
                self.gg_updateCollectionViewInsets()
                if (self.automaticallyScrollsToMostRecentMessage) {
                    self.scrollToBottomAnimated(false)
                }
            }
        }
    }

    // pragma mark - Keyboard controller delegate
    
    func keyboardController(keyboardController: MessageKeyboardController,
        keyboardDidChangeFrame keyboardFrame: CGRect) {
        if (!self.inputToolbar.contentView.textView.isFirstResponder() && self.toolbarBottomLayoutGuide.constant == 0.0) {
            return
        }

        var heightFromBottom: CGFloat = CGRectGetMaxY(self.messageCollectionView.frame) - CGRectGetMinY(keyboardFrame)

        heightFromBottom = max(0.0, heightFromBottom)

        self.gg_setToolbarBottomLayoutGuideConstant(heightFromBottom)
    }

    func gg_setToolbarBottomLayoutGuideConstant(constant: CGFloat) {
        self.toolbarBottomLayoutGuide.constant = constant
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()

        self.gg_updateCollectionViewInsets()
    }

    func gg_updateKeyboardTriggerPoint() {
        // self.keyboardController.keyboardTriggerPoint = CGPointMake(0.0, CGRectGetHeight(self.inputToolbar.bounds))
    }

    // pragma mark - Gesture recognizers

    func gg_handleInteractivePopGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerState.Began:
                /*
                if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                    self.snapshotView!.removeFromSuperview()
                }

                self.textViewWasFirstResponderDuringInteractivePop = self.inputToolbar.contentView.textView.isFirstResponder()

                self.keyboardController.endListeningForKeyboard()

                if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                    self.inputToolbar.contentView.textView.resignFirstResponder()
                    UIView.animateWithDuration(0.0,
                        animations: {
                            self.gg_setToolbarBottomLayoutGuideConstant(0.0)
                        })

                    let snapshot: UIView = self.view.snapshotViewAfterScreenUpdates(true)
                    self.view.addSubview(snapshot)
                    self.snapshotView = snapshot
                }
                */
                break;
            case UIGestureRecognizerState.Changed:
                break;
            case UIGestureRecognizerState.Cancelled, UIGestureRecognizerState.Ended,UIGestureRecognizerState.Failed:
                /*
                self.keyboardController.beginListeningForKeyboard()
                if (self.textViewWasFirstResponderDuringInteractivePop) {
                    self.inputToolbar.contentView.textView.becomeFirstResponder()
                }

                if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                    self.snapshotView!.removeFromSuperview()
                }
                */
                break
            default:
                break
        }
    }

    // pragma mark - Input toolbar utilities

    func gg_inputToolbarHasReachedMaximumHeight() -> Bool {
        // return CGRectGetMinY(self.inputToolbar.frame) == (self.topLayoutGuide.length + self.topContentAdditionalInset)
        return true
    }

    func gg_adjustInputToolbarForComposerTextViewContentSizeChange(var dy: CGFloat) {
        let contentSizeIsIncreasing: Bool = (dy > 0)

        if (self.gg_inputToolbarHasReachedMaximumHeight()) {
            let contentOffsetIsPositive: Bool = (self.inputToolbar.contentView.textView.contentOffset.y > 0)

            if (contentSizeIsIncreasing || contentOffsetIsPositive) {
                self.gg_scrollComposerTextViewToBottomAnimated(true)
                return
            }
        }

        let toolbarOriginY: CGFloat = CGRectGetMinY(self.inputToolbar.frame)
        let newToolbarOriginY: CGFloat = toolbarOriginY - dy

        //  attempted to increase origin.Y above topLayoutGuide
        if (newToolbarOriginY <= self.topLayoutGuide.length + self.topContentAdditionalInset) {
            dy = toolbarOriginY - (self.topLayoutGuide.length + self.topContentAdditionalInset)
            self.gg_scrollComposerTextViewToBottomAnimated(true)
        }

        self.gg_adjustInputToolbarHeightConstraintByDelta(dy)

        self.gg_updateKeyboardTriggerPoint()

        if (dy < 0) {
            self.gg_scrollComposerTextViewToBottomAnimated(false)
        }
    }

    func gg_adjustInputToolbarHeightConstraintByDelta(dy: CGFloat) {
        let proposedHeight: CGFloat = self.toolbarHeightConstraint.constant + dy

        var finalHeight: CGFloat = max(proposedHeight, self.inputToolbar.preferredDefaultHeight)

        if (self.inputToolbar.maximumHeight != NSNotFound) {
            finalHeight = min(finalHeight, CGFloat(self.inputToolbar.maximumHeight))
        }

        if (self.toolbarHeightConstraint.constant != finalHeight) {
            self.toolbarHeightConstraint.constant = finalHeight
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }
    }

    func gg_scrollComposerTextViewToBottomAnimated(animated: Bool) {
        let textView: UITextView = self.inputToolbar.contentView.textView
        let contentOffsetToShowLastLine: CGPoint = CGPointMake(0.0, textView.contentSize.height - CGRectGetHeight(textView.bounds))

        if (!animated) {
            textView.contentOffset = contentOffsetToShowLastLine
            return
        }

        UIView.animateWithDuration(0.01,
            delay: 0.01,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                textView.contentOffset = contentOffsetToShowLastLine
            },
            completion:nil)
    }

    // pragma mark - Collection view utilities

    func gg_updateCollectionViewInsets() {
        self.gg_setCollectionViewInsetsTopValue(self.topLayoutGuide.length + self.topContentAdditionalInset,
            bottomValue: CGRectGetMaxY(self.messageCollectionView.frame) - CGRectGetMinY(self.inputToolbar.frame))
    }

    func gg_setCollectionViewInsetsTopValue(top: CGFloat, bottomValue bottom: CGFloat) {
        let insets: UIEdgeInsets = UIEdgeInsetsMake(top, 0.0, bottom, 0.0)
        self.messageCollectionView.contentInset = insets
        self.messageCollectionView.scrollIndicatorInsets = insets
    }

    func gg_isMenuVisible() -> Bool {
        //  check if cell copy menu is showing
        //  it is only our menu if `selectedIndexPathForMenu` is not `nil`
        return self.selectedIndexPathForMenu != nil && UIMenuController.sharedMenuController().menuVisible
    }

    // pragma mark - Utilities

    func gg_addObservers() {
        if (self.gg_isObserving) {
            return
        }
        self.inputToolbar.contentView.textView.addObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("contentSize")),
            options: NSKeyValueObservingOptions(rawValue: NSKeyValueObservingOptions.Old.rawValue | NSKeyValueObservingOptions.New.rawValue),
            context: MessageViewController.kMessagesKeyValueObservingContext)
        
        self.gg_isObserving = true
    }

    func gg_removeObservers() {
        if (!self.gg_isObserving) {
            return
        }

        self.inputToolbar.contentView.textView.removeObserver(
            self,
            forKeyPath: NSStringFromSelector(Selector("contentSize")),
            context: MessageViewController.kMessagesKeyValueObservingContext)

        self.gg_isObserving = false
    }

    func gg_registerForNotifications(registerForNotifications: Bool) {
        if (registerForNotifications) {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("gg_handleDidChangeStatusBarFrameNotification:"),
                name: UIApplicationDidChangeStatusBarFrameNotification,
                object: nil)

            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("gg_didReceiveMenuWillShowNotification:"),
                name: UIMenuControllerWillShowMenuNotification,
                object: nil)

            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("gg_didReceiveMenuWillHideNotification:"),
                name: UIMenuControllerWillHideMenuNotification,
                object:nil)
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(
                self,
                name: UIApplicationDidChangeStatusBarFrameNotification,
                object:nil)

            NSNotificationCenter.defaultCenter().removeObserver(
                self,
                name: UIMenuControllerWillShowMenuNotification,
                object:nil)

            NSNotificationCenter.defaultCenter().removeObserver(
                self,
                name: UIMenuControllerWillHideMenuNotification,
                object:nil)
        }
    }
    
    func gg_addActionToInteractivePopGestureRecognizer(addAction: Bool) {
        if (self.currentInteractivePopGestureRecognizer != nil) {
            self.currentInteractivePopGestureRecognizer!.removeTarget(
                nil,
                action: Selector("gg_handleInteractivePopGestureRecognizer:"))
            self.currentInteractivePopGestureRecognizer = nil
        }

        if (addAction) {
            self.navigationController!.interactivePopGestureRecognizer!.addTarget(
                self,
                action: Selector("gg_handleInteractivePopGestureRecognizer:"))
            self.currentInteractivePopGestureRecognizer = self.navigationController!.interactivePopGestureRecognizer
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    // MessageCollectionFlowLayoutDelegate
    ///////////////////////////////////////////////////////////////////////////////

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let messageCollectionViewLayout = collectionViewLayout as! MessagesCollectionViewFlowLayout
        return messageCollectionViewLayout.sizeForItemAtIndexPath(indexPath)
    }
    
    /**
     *  Asks the delegate for the height of the `cellTopLabel` for the item at the specified indexPath.
     *
     *  @param collectionView       The collection view object displaying the flow layout.
     *  @param collectionViewLayout The layout object requesting the information.
     *  @param indexPath            The index path of the item.
     *
     *  @return The height of the `cellTopLabel` for the item at indexPath.
     *
     *  @see JSQMessagesCollectionViewCell.
     */
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewFlowLayout,
        heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.item % 3 == 0) {
            return MessagesCollectionViewFlowLayout.kMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    /**
     *  Asks the delegate for the height of the `messageBubbleTopLabel` for the item at the specified indexPath.
     *
     *  @param collectionView       The collection view object displaying the flow layout.
     *  @param collectionViewLayout The layout object requesting the information.
     *  @param indexPath            The index path of the item.
     *
     *  @return The height of the `messageBubbleTopLabel` for the item at indexPath.
     *
     *  @see JSQMessagesCollectionViewCell.
     */
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewFlowLayout,
        heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        /**
        *  iOS7-style sender name labels
        */
        let currentMessage: Message = GGModelData.sharedInstance.messages[indexPath.item]
        if (currentMessage.senderId == self.senderId) {
            return 0.0
        }
        
        if (indexPath.item - 1 > 0) {
            let previousMessage: Message = GGModelData.sharedInstance.messages[indexPath.item - 1]
            if (previousMessage.senderId == currentMessage.senderId) {
                return 0.0
            }
        }
        
        return MessagesCollectionViewFlowLayout.kMessagesCollectionViewCellLabelHeightDefault
    }
    
    /**
     *  Asks the delegate for the height of the `cellBottomLabel` for the item at the specified indexPath.
     *
     *  @param collectionView       The collection view object displaying the flow layout.
     *  @param collectionViewLayout The layout object requesting the information.
     *  @param indexPath            The index path of the item.
     *
     *  @return The height of the `cellBottomLabel` for the item at indexPath.
     *
     *  @see JSQMessagesCollectionViewCell.
     */
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewFlowLayout,
        heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 0.0
    }

    //////////////////////////////////////////////////////////////////////////////////
    // MessageCollectionView delegate methods
    //////////////////////////////////////////////////////////////////////////////////
    /**
     *  Notifies the delegate that the avatar image view at the specified indexPath did receive a tap event.
     *
     *  @param collectionView  The collection view object that is notifying the delegate of the tap event.
     *  @param avatarImageView The avatar image view that was tapped.
     *  @param indexPath       The index path of the item for which the avatar was tapped.
     */
    func collectionView(collectionView: MessagesCollectionView,
        didTapAvatarImageView avatarImageView: UIImageView,
        atIndexPath indexPath: NSIndexPath) {
        print("MVC::didTapAvatarImageView")
    }

    /**
     *  Notifies the delegate that the message bubble at the specified indexPath did receive a tap event.
     *
     *  @param collectionView The collection view object that is notifying the delegate of the tap event.
     *  @param indexPath      The index path of the item for which the message bubble was tapped.
     */
    func collectionView(collectionView: MessagesCollectionView,
        didTapMessageBubbleAtIndexPath indexPath: NSIndexPath) {
        print("MVC::didTapMessageBubbleAtIndexPath")
    }

    /**
     *  Notifies the delegate that the cell at the specified indexPath did receive a tap event at the specified touchLocation.
     *
     *  @param collectionView The collection view object that is notifying the delegate of the tap event.
     *  @param indexPath      The index path of the item for which the message bubble was tapped.
     *  @param touchLocation  The location of the touch event in the cell's coordinate system.
     *
     *  @warning This method is *only* called if position is *not* within the bounds of the cell's
     *  avatar image view or message bubble image view. In other words, this method is *not* called when the cell's
     *  avatar or message bubble are tapped. There are separate delegate methods for these two cases.
     *
     *  @see `collectionView:didTapAvatarImageView:atIndexPath:`
     *  @see `collectionView:didTapMessageBubbleAtIndexPath:atIndexPath:`
     */
    func collectionView(collectionView: MessagesCollectionView,
        didTapCellAtIndexPath indexPath: NSIndexPath,
        touchLocation: CGPoint) {
        print("MVC::didTapCellAtIndexPath")
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    // MessageLoadEarlierHeaderView delegate methods
    //////////////////////////////////////////////////////////////////////////////////
    /**
     *  Notifies the delegate that the collection view's header did receive a tap event.
     *
     *  @param collectionView The collection view object that is notifying the delegate of the tap event.
     *  @param headerView     The header view in the collection view.
     *  @param sender         The button that was tapped.
     */
    func collectionView(collectionView: MessagesCollectionView,
        header headerView: MessageLoadEarlierHeaderView,
        didTapLoadEarlierMessagesButton sender: UIButton) {
        print("didTapLoadEarlierMessagesButton")
    }
}