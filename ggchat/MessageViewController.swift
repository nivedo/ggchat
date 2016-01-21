//
//  MessageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/16/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageVariable {
    var variableName: String
    var displayText: String
    var assetId: String
    var assetURL: String
    var placeholderURL: String?
    
    init(variableName: String, displayText: String, assetId: String, assetURL: String, placeholderURL: String?) {
        self.variableName = variableName
        self.displayText = displayText
        self.assetId = assetId
        self.assetURL = assetURL
        self.placeholderURL = placeholderURL
    }
}

class MessagePacket {
    static let delimiter = "__ggchat::link__"
    
    var placeholderText: String
    var encodedText: String
    var variables = [MessageVariable]()
    
    init(placeholderText: String, encodedText: String) {
        self.placeholderText = placeholderText
        self.encodedText = encodedText
    }
    
    var description: String {
        get {
            return self.encodedText
        }
    }
    
    var isSingleEncodedAsset: Bool {
        get {
            if self.variables.count == 1 {
                return self.encodedText == MessagePacket.delimiter
            }
            return false
        }
    }
    
    func getSingleEncodedAsset() -> GGWikiAsset? {
        // print("isSingleEncodedAsset: \(self.encodedText) --> \(self.isSingleEncodedAsset)")
        if self.isSingleEncodedAsset {
            let v = self.variables[0]
            return GGWiki.sharedInstance.addAsset(v.assetId, url: v.assetURL, displayName: v.displayText, placeholderURL: v.placeholderURL)
        }
        return nil
    }
    
    func message(id: String,
        senderId: String,
        date: NSDate,
        delegate: MessageMediaDelegate?) -> Message {
        let isOutgoing = UserAPI.sharedInstance.isOutgoingJID(senderId)
            
        let attributedText = self.tappableText(isOutgoing ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor)
        if let asset = self.getSingleEncodedAsset() {
            let wikiMedia: WikiMediaItem = WikiMediaItem(imageURL: asset.url, placeholderURL: asset.placeholderURL, delegate: delegate)
            let message = Message(
                id: id,
                senderId: senderId,
                senderDisplayName: UserAPI.sharedInstance.getDisplayName(senderId),
                isOutgoing: isOutgoing,
                date: date,
                media: wikiMedia,
                attributedText: attributedText)
            return message
        }
        let fullMessage = Message(
            id: id,
            senderId: senderId,
            senderDisplayName: UserAPI.sharedInstance.getDisplayName(senderId),
            isOutgoing: isOutgoing,
            date: date,
            attributedText: attributedText)
        
        return fullMessage
    }
    
    func tappableText(textColor: UIColor) -> NSAttributedString {
        let paragraph = NSMutableAttributedString(string: "")
        let tokens = self.encodedText.componentsSeparatedByString(MessagePacket.delimiter)
        if tokens.count == self.variables.count+1 {
            for (i, token) in tokens.enumerate() {
                if token.length > 0 {
                    let str = token
                    let attr: [String : NSObject] = [
                        NSFontAttributeName : GGConfig.messageBubbleFont,
                        NSForegroundColorAttributeName : textColor
                    ]
                    let attributedString = NSAttributedString(
                        string: str,
                        attributes: attr)
                    paragraph.appendAttributedString(attributedString)
                }
                if i < self.variables.count {
                    let variable = self.variables[i]
                    var attr: [String : NSObject] = [
                        NSFontAttributeName : GGConfig.messageBubbleFont,
                        NSForegroundColorAttributeName : textColor
                    ]
                    attr[TappableText.tapAttributeKey] = true
                    attr[TappableText.tapAssetId] = variable.assetId
                    attr[NSForegroundColorAttributeName] = UIColor.gg_highlightedColor()
                        
                    GGWiki.sharedInstance.addAsset(
                        variable.assetId,
                        url: variable.assetURL,
                        displayName: variable.displayText,
                        placeholderURL: variable.placeholderURL)
                    let attributedString = NSAttributedString(
                        string: variable.displayText,
                        attributes: attr)
                    paragraph.appendAttributedString(attributedString)
                }
            }
        } else {
            let str = self.placeholderText
            let attr: [String : NSObject] = [
                NSFontAttributeName : GGConfig.messageBubbleFont,
                NSForegroundColorAttributeName : textColor
            ]
            let attributedString = NSAttributedString(
                string: str,
                attributes: attr)
            paragraph.appendAttributedString(attributedString)
        }
        
        return paragraph.copy() as! NSAttributedString
    }
    
    func addVariable(variableName: String, displayText: String, assetId: String, assetURL: String, placeholderURL: String?) {
        self.variables.append(MessageVariable(
            variableName: variableName,
            displayText: displayText,
            assetId: assetId,
            assetURL: assetURL,
            placeholderURL: placeholderURL
            ))
    }
}

class MessageViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    MessageInputToolbarDelegate,
    MessageKeyboardControllerDelegate,
    MessageComposerTextViewPasteDelegate,
    MessageAutocompleteControllerDelegate,
    MessageMediaDelegate,
    UITextViewDelegate {
    
    static let kMessagesKeyValueObservingContext = UnsafeMutablePointer<Void>()
    
    //////////////////////////////////////////////////////////////////////////////////
    // Properties
    //////////////////////////////////////////////////////////////////////////////////
    
    @IBOutlet weak var messageCollectionView: MessagesCollectionView!
    @IBOutlet weak var inputToolbar: MessageInputToolbar!
    var keyboardController: MessageKeyboardController?
    var autocompleteController: MessageAutocompleteController?
    
    var automaticallyScrollsToMostRecentMessage: Bool = true
    var outgoingCellIdentifier: String = OutgoingMessagesCollectionViewCell.cellReuseIdentifier()
    var outgoingMediaCellIdentifier: String = OutgoingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    var incomingCellIdentifier: String = IncomingMessagesCollectionViewCell.cellReuseIdentifier()
    var incomingMediaCellIdentifier: String = IncomingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    
    var gg_isObserving: Bool = false
    var currentInteractivePopGestureRecognizer: UIGestureRecognizer?
    var textViewWasFirstResponderDuringInteractivePop: Bool = false
    var overrideNavBackButtonToRootViewController: Bool = false
    var snapshotView: UIView?
    var messageImageViewController: MessageImageViewController?
    
    var messages: [Message] = [Message]()
    
    // pragma mark - Setters
    
    var showTypingIndicator: Bool = false {
        didSet {
            if self.messageCollectionView != nil {
                self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
                self.messageCollectionView.collectionViewLayout.invalidateLayout()
            }
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
    
    func initMessageImageViewController() {
        let storyboardName: String = "Main"
        let storyboard: UIStoryboard = UIStoryboard(name: storyboardName, bundle: nil)
        self.messageImageViewController = storyboard.instantiateViewControllerWithIdentifier("Message Image View Controller") as? MessageImageViewController
    }
    
    func setup() {
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.toolbarHeightConstraint.constant = self.inputToolbar.preferredDefaultHeight
        
        self.messageCollectionView.dataSource = self
        self.messageCollectionView.delegate = self
        // self.inputToolbar.contentView.textView.delegate = self
        
        self.inputToolbar.delegate = self
        self.inputToolbar.contentView.textView.placeHolder = NSBundle.gg_localizedStringForKey("new_message")
        self.inputToolbar.contentView.textView.delegate = self
        self.messageCollectionView.messageCollectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        // NOTE: let this behavior be opt-in for now
        MessagesCollectionViewCell.registerMenuAction(Selector("delete:"))
        
        self.gg_updateCollectionViewInsets()
        
        // Don't set keyboardController if client creates custom content view via -loadToolbarContentView
        if (self.inputToolbar.contentView.textView != nil) {
            self.keyboardController = MessageKeyboardController(
                textView: self.inputToolbar.contentView.textView,
                contextView: self.view,
                panGestureRecognizer: self.messageCollectionView.panGestureRecognizer,
                delegate: self)
            
            self.autocompleteController = MessageAutocompleteController(
                delegate: self)
            self.view.addSubview(self.autocompleteController!.tableView)
            
            if let wiki = GGWiki.sharedInstance.getAutocompleteResource() {
                self.autocompleteController?.active = true
                self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(wiki.iconImage)
            }
        }
        
        // Navigation bar
        self.tabBarController?.tabBar.hidden = true
        // self.navigationController!.navigationBarHidden = false
        // self.navigationController!.navigationBar.hidden = false
        
        /*
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.gg_defaultTypingIndicatorImage(),
            style: UIBarButtonItemStyle.Bordered,
            target: self,
            action: Selector("receiveMessagePressed:"))
        */
        // self.navigationItem.leftItemsSupplementBackButton = true
        // self.navigationItem.hidesBackButton = false
        // self.navigationController!.navigationBar.topItem!.title = "Back"
        /*
        let barButton: UIBarButtonItem = UIBarButtonItem()
        barButton.title = "Back"
        self.navigationController!.navigationBar.topItem!.backBarButtonItem = barButton
        */
        /*
        if (self.overrideNavBackButtonToRootViewController) {
            let barButton: UIBarButtonItem = UIBarButtonItem(
                title: "Chats",
                style: UIBarButtonItemStyle.Plain,
                target: self,
                action: Selector("receivedBackPressed:"))
            self.navigationItem.leftBarButtonItem = barButton
        }
        */
        self.initBackButton()
        self.initOptionButton()
        
        // Tap gesture recognizer to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard"))
        self.messageCollectionView.addGestureRecognizer(tap)
        
        /**
         *  Register custom menu actions for cells.
         */
        MessagesCollectionViewCell.registerMenuAction(Selector("customAction:"))
        UIMenuController.sharedMenuController().menuItems = [
            UIMenuItem(
                title: "Custom Action",
                action: Selector("customAction:")) ]

        /**
         *  OPT-IN: allow cells to be deleted
         */
        MessagesCollectionViewCell.registerMenuAction(Selector("delete:"))

        /**
         *  Set a maximum height for the input toolbar
         *
         */
        self.inputToolbar.maximumHeight = 150
        
    }
    
    func initBackButton() {
        let totalUnreadCount = UserAPI.sharedInstance.totalUnreadCount
        var text = "Back"
        if totalUnreadCount > 0 {
            text = "Back (\(totalUnreadCount))"
        }
        let barButton: UIBarButtonItem = UIBarButtonItem(
            title: text,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedBackPressed:"))
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func initOptionButton() {
        let barButton: UIBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ArrowDown"),
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedOptionPressed:"))
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func receivedBackPressed(button: UIBarButtonItem) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func receivedOptionPressed(button: UIBarButtonItem) {
        let alert: UIAlertController = UIAlertController(
            title: "Autocomplete",
            message: "Choose game",
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        for (k,v) in GGWiki.sharedInstance.wikis {
            if v.language == UserAPI.sharedInstance.settings.language {
                let action = UIAlertAction(
                    title: v.name,
                    style: UIAlertActionStyle.Default) { action -> Void in
                        GGWiki.sharedInstance.loadAutocompleteAsync(k)
                        
                        self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(v.iconImage)
                        self.autocompleteController?.active = true
                }
                alert.addAction(action)
            }
        }
        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /////////////////////////////////////////////////////////////////////////////
    // UICollectionViewController methods
    /////////////////////////////////////////////////////////////////////////////
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // print("MessageViewController::awakeFromNib()")
    }
    
    override func viewDidLoad() {
        // print("MessageViewController::viewDidLoad()")
        super.viewDidLoad()
        
        // Load outlets to self
        let nib = UINib(nibName: "MessageViewController", bundle: NSBundle.mainBundle())
        nib.instantiateWithOwner(self, options: nil)

        self.gg_registerForNotifications(true)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Register cell classes
        
        // Do any additional setup after loading the view.
        self.setup()
        self.tabBarController?.tabBar.hidden = true
        self.initMessageImageViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        // self.navigationItem.title = nil
    }

    ///////////////////////////////////////////////////////////////////////////////
    // MARK: UICollectionViewDataSource
    ///////////////////////////////////////////////////////////////////////////////

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        // print("MVC::numberOfSectionsInCollectionView")
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // print("MVC::numberOfItemsInSection: \(self.messages.count)")
        return self.messages.count
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
        let data = self.messages[indexPath.row]
        return data
    }
    
    func collectionView(collectionView: MessagesCollectionView,
        didDeleteMessageAtIndexPath indexPath: NSIndexPath) {
        print("MVC::didDeleteMessageAtIndexPath")
        self.messages.removeAtIndex(indexPath.row)
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    
    func collectionView(collectionView: MessagesCollectionView, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageBubbleImage? {
        // print("MVC::messageBubbleImageDataForItemAtIndexPath")
        /**
        *  You may return nil here if you do not want bubbles.
        *  In this case, you should set the background color of your collection view cell's textView.
        *
        *  Otherwise, return your previously created bubble image data objects.
        */
        // return nil
        let message: Message = self.messages[indexPath.item]
    
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
        let message: Message = self.messages[indexPath.item]
        if (message.senderId == self.senderId) {
            return nil
        }

        return UserAPI.sharedInstance.getAvatarImage(message.senderId)
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        // print("MVC::attributedTextForCellTopLabelAtIndexPath")
        /**
        *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
        *  The other label text delegate methods should follow a similar pattern.
        *
        *  Show a timestamp for every 3rd message
        */
        /*
        if (indexPath.item % 3 == 0) {
            // let message: Message = self.messages[indexPath.item]
            let message: Message = self.messages[indexPath.item]
            return MessageTimestampFormatter.sharedInstance.attributedTimestampForDate(message.date)
        }
        */
        if let date = collectionView.messageDataSource.dateForTopLabelAtIndexPath(collectionView, indexPath: indexPath) {
            return NSAttributedString(string: date)
        }
        return nil;
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        // print("MVC::attributedTextForMessageBubbleTopLabelAtIndexPath")
        // let message: Message = self.messages[indexPath.item]
        let message: Message = self.messages[indexPath.item]
        
        /**
        *  iOS7-style sender name labels
        */
        if (message.senderId == self.senderId) {
            return nil
        }
        
        if (indexPath.item - 1 > 0) {
            // let previousMessage: Message = self.messages[indexPath.item - 1]
            let previousMessage: Message = self.messages[indexPath.item - 1]
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
        // print("MessageViewController::viewWillAppear()")
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        self.messageCollectionView.collectionViewLayout.invalidateLayout()
        
        self.tabBarController?.tabBar.hidden = true

        if (self.automaticallyScrollsToMostRecentMessage) {
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollToBottomAnimated(false)
                self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
            }
        }

        self.gg_updateKeyboardTriggerPoint()
        ConnectionManager.checkConnection(self)
    }

    override func viewDidAppear(animated: Bool) {
        // print("MessageViewController::viewDidAppear()")
        super.viewDidAppear(animated)
        self.gg_addObservers()
        self.gg_addActionToInteractivePopGestureRecognizer(true)
        self.keyboardController!.beginListeningForKeyboard()

        if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
            self.snapshotView!.removeFromSuperview()
        }
        self.messageCollectionView.messageCollectionViewLayout.springinessEnabled = GGConfig.springinessEnabled
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.messageCollectionView.messageCollectionViewLayout.springinessEnabled = false // true
        self.tabBarController?.tabBar.hidden = false
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.gg_addActionToInteractivePopGestureRecognizer(false)
        self.gg_removeObservers()
        self.keyboardController!.endListeningForKeyboard()
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        // print("willMoveToParentViewController")
        
        self.tabBarController?.tabBar.hidden = false
        // parent?.tabBarController?.tabBar.hidden = false
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
            // self.showTypingIndicator = true
            self.messageCollectionView.reloadData()
        }
    }

    // pragma mark - Messages view controller

    func didPressSendButton(
        button: UIButton,
        withMessagePacket packet: MessagePacket,
        senderId: String,
        senderDisplayName: String,
        date: NSDate) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressSendButton")
    }

    func didPressAccessoryButton(sender: UIButton) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressAccessoryButton")
    }

    func didPressLeftButton(sender: UIButton) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressLeftButton")
    }
    
    func didPressInnerButton(sender: UIButton) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressInnerButton")
    }
    
    func didPressEllipsisButton(sender: UIButton) {
        assert(false, "Error! required method not implemented in subclass. Need to implement didPressEllipsisButton")
    }

    func finishSendingMessage() {
        self.finishSendingMessageAnimated(true)
    }

    func finishSendingMessageAnimated(animated: Bool) {
        // print("finishSendingMessageAnimated")
        let textView: UITextView = self.inputToolbar.contentView.textView
        textView.text = nil
        textView.undoManager!.removeAllActions()

        self.autocompleteController?.hide()
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
        // print("finishReceivingMessageAnimated")
        if self.messageCollectionView != nil {
            self.showTypingIndicator = false

            self.messageCollectionView.messageCollectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
            self.messageCollectionView.reloadData()

            if (self.automaticallyScrollsToMostRecentMessage && !self.gg_isMenuVisible()) {
                self.scrollToBottomAnimated(animated)
            }
        }
    }

    func scrollToBottomAnimated(animated: Bool) {
        if self.messageCollectionView == nil {
            return
        }
        if (self.messageCollectionView.numberOfSections() == 0) {
            return
        }

        let items = self.messageCollectionView.numberOfItemsInSection(0)

        if (items == 0) {
            return;
        }
       
        let maxHeightForVisibleMessage: CGFloat = CGRectGetHeight(self.messageCollectionView.bounds) - self.messageCollectionView.contentInset.top - CGRectGetHeight(self.inputToolbar.bounds)
        let collectionViewContentHeight: CGFloat = self.messageCollectionView.messageCollectionViewLayout.collectionViewContentSize().height
        // let isContentTooSmall: Bool = (collectionViewContentHeight < CGRectGetHeight(self.messageCollectionView.bounds))
        let isContentTooSmall: Bool = (collectionViewContentHeight < maxHeightForVisibleMessage)

        /*
        print("scrollToBottomAnimated animated: \(animated), isContentTooSmall: \(isContentTooSmall)")
        print(collectionViewContentHeight)
        print(CGRectGetHeight(self.messageCollectionView.bounds))
        print(maxHeightForVisibleMessage)
        */
        
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

        // let maxHeightForVisibleMessage: CGFloat = CGRectGetHeight(self.messageCollectionView.bounds) - self.messageCollectionView.contentInset.top - CGRectGetHeight(self.inputToolbar.bounds)

        let scrollPosition: UICollectionViewScrollPosition = (finalCellSize.height > maxHeightForVisibleMessage) ? UICollectionViewScrollPosition.Bottom : UICollectionViewScrollPosition.Top
        
        // print("finalCellSize: \(finalCellSize), scrollPosition: \(scrollPosition)")

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
        // print("-------> index: \(indexPath.row)/\(self.messages.count), media: \(isMediaMessage), identifier: \(cellIdentifier), sender: \(messageSenderId)")
            
        let cell: MessagesCollectionViewCell = messageCollectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath:indexPath) as! MessagesCollectionViewCell
        cell.delegate = collectionView

        // print(cell)
        
        // This is a HACK, should be in init of cell
        if (isOutgoingMessage) {
            cell.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right
            cell.cellBottomLabel.textAlignment = NSTextAlignment.Right
            cell.timeLabel.textAlignment = NSTextAlignment.Right
            cell.textView.textColor = GGConfig.outgoingTextColor
            
            if let outgoingCell = cell as? OutgoingMessagesCollectionViewCell {
                outgoingCell.mark(messageItem.isFailedToSend, read: messageItem.isRead)
                outgoingCell.setIsComposing(messageItem.isComposing)
            }
        } else {
            cell.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left
            cell.cellBottomLabel.textAlignment = NSTextAlignment.Left
            cell.timeLabel.textAlignment = NSTextAlignment.Left
            cell.textView.textColor = GGConfig.incomingTextColor
        }
            
        cell.timeLabel.text = MessageTimestampFormatter.sharedInstance.timeForDate(messageItem.date)

        if (!isMediaMessage) {
            cell.textView.text = messageItem.displayText
            if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                //  workaround for iOS 7 textView data detectors bug
                cell.textView.text = nil
                cell.textView.attributedText = NSAttributedString(
                    string: messageItem.displayText,
                    attributes: [ NSFontAttributeName : messageCollectionView.messageCollectionViewLayout.messageBubbleFont ])
            }
            if SettingManager.sharedInstance.tappableMessageText {
                // let textColor = isOutgoingMessage ? GGConfig.outgoingTextColor : GGConfig.incomingTextColor
                cell.textView.text = nil
                cell.textView.attributedText = messageItem.attributedText
                    // messageItem.textAsAttributedStringForView(textColor,
                    // attributes: nil)
                    // [
                    // NSFontAttributeName: messageCollectionView.messageCollectionViewLayout.messageBubbleFont
                    // ])
            }
            if let bubbleImageDataSource = messageCollectionView.messageDataSource.collectionView(collectionView, messageBubbleImageDataForItemAtIndexPath:indexPath) {
                cell.messageBubbleImageView.image = bubbleImageDataSource.messageBubbleImage
                cell.messageBubbleImageView.highlightedImage = bubbleImageDataSource.messageBubbleHighlightedImage
            } else {
                cell.textView.backgroundColor = GGConfig.incomingBubbleColor
            }
        } else {
            let messageMedia: MessageMediaData = messageItem.media!
           
            if let mediaItem = messageMedia as? MediaItem {
                mediaItem.appliesMediaViewMaskAsOutgoing = isOutgoingMessage
            }
            // print(cell.messageBubbleImageView)
            cell.mediaView = (messageMedia.mediaView() != nil ? messageMedia.mediaView() : messageMedia.mediaPlaceholderView())!
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

        let bubbleTopLabelInset: CGFloat = (avatarImageDataSource != nil) ? cell.avatarContainerViewWidthConstraint.constant : 15.0

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
        // print("MVC::viewForSupplementaryElementOfKind, kind: \(kind)")
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
            UIPasteboard.generalPasteboard().string = messageData.displayText
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
        didPressMiddle1BarButton sender: UIButton) {
        print("MVC::didPressMiddle1BarButton")
    }
    
    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressMiddle2BarButton sender: UIButton) {
        print("MVC::didPressMiddle2BarButton")
    }

    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressMiddle3BarButton sender: UIButton) {
        print("MVC::didPressMiddle3BarButton")
    }
    
    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressLeftBarButton sender: UIButton) {
        print("MVC::didPressLeftBarButton")
        self.didPressLeftButton(sender)
        /*
        if (toolbar.sendButtonOnRight) {
            self.didPressAccessoryButton(sender)
        } else {
            self.didPressSendButton(sender,
                withMessagePacket: self.gg_currentlyComposedMessageText(),
                senderId: self.senderId,
                senderDisplayName: self.senderDisplayName,
                date: NSDate())
        }
        */
    }
    
    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressLeftInnerBarButton sender: UIButton) {
        print("MVC::didPressLeftInnerBarButton")
        // self.autocompleteController?.hide()
        // self.didPressInnerButton(sender)
        self.didPressAccessoryButton(sender)
    }
    
    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressRightInnerBarButton sender: UIButton) {
        print("MVC::didPressRightInnerBarButton")
        self.autocompleteController?.hide()
        self.didPressEllipsisButton(sender)
    }

    func messagesInputToolbar(toolbar: MessageInputToolbar,
        didPressRightBarButton sender: UIButton) {
        print("MVC::didPressRightBarButton")
        self.didPressSendButton(sender,
            withMessagePacket: self.gg_currentlyComposedMessageText(),
            senderId: self.senderId,
            senderDisplayName: self.senderDisplayName,
            date: NSDate())
        /*
        if (toolbar.sendButtonOnRight) {
            self.didPressSendButton(sender,
                withMessagePacket: self.gg_currentlyComposedMessageText(),
                senderId: self.senderId,
                senderDisplayName: self.senderDisplayName,
                date: NSDate())
        } else {
            self.didPressAccessoryButton(sender)
        }
        */
    }

    func gg_currentlyComposedMessageText() -> MessagePacket {
        //  auto-accept any auto-correct suggestions
        self.inputToolbar.contentView.textView.inputDelegate?.selectionWillChange(self.inputToolbar.contentView.textView)
        
        self.inputToolbar.contentView.textView.inputDelegate?.selectionDidChange(self.inputToolbar.contentView.textView)

        let currentAttributedText = NSMutableAttributedString(attributedString: self.inputToolbar.contentView.textView.attributedText)
        let placeholderText = currentAttributedText.string.gg_stringByTrimingWhitespace()
        
        // print("Initial send string: \(currentAttributedText)")
        var variables = [MessageVariable]()
        
        currentAttributedText.enumerateAttribute(
            TappableText.tapAssetId,
            inRange: NSMakeRange(0, currentAttributedText.length),
            options: NSAttributedStringEnumerationOptions.LongestEffectiveRangeNotRequired,
            usingBlock: { (value: AnyObject?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                if let id = value as? String {
                    let displayText = (currentAttributedText.string as NSString).substringWithRange(range) as String
                    // let replaceText = "||\(id)|\(GGWiki.sharedInstance.getAssetImageURL(id))|\(displayText)||"
                    let replaceText = MessagePacket.delimiter
                    currentAttributedText.replaceCharactersInRange(range, withString: replaceText)
                    
                    variables.append(MessageVariable(
                        variableName: "$\(variables.count)",
                        displayText: displayText,
                        assetId: id,
                        assetURL: GGWiki.sharedInstance.getAssetImageURL(id),
                        placeholderURL: GGWiki.sharedInstance.getAssetPlaceholderURL(id)))
                }
            }
        )
        // print("Final string to send: \(currentAttributedText.string.gg_stringByTrimingWhitespace())")
        let encodedText = currentAttributedText.string.gg_stringByTrimingWhitespace()
        let packet = MessagePacket(placeholderText: placeholderText, encodedText: encodedText)
        packet.variables = variables
        return packet
    }
    
    func gg_currentlyTypedMessageText() -> (String, Int) {
        var index: Int = 0
        
        let currentAttributedText = NSAttributedString(attributedString: self.inputToolbar.contentView.textView.attributedText)
        currentAttributedText.enumerateAttribute(
            TappableText.tapAttributeKey,
            inRange: NSMakeRange(0, currentAttributedText.length),
            options: NSAttributedStringEnumerationOptions.LongestEffectiveRangeNotRequired,
            usingBlock: { (value: AnyObject?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                if let tappable = value as? Bool {
                    if tappable {
                        index = max(index, range.location + range.length)
                    }
                }
            }
        )
        
        let length = currentAttributedText.length - index
        let validAttributedText = currentAttributedText.attributedSubstringFromRange(NSMakeRange(index, length))
        // print("\(currentAttributedText.string) --> \(validAttributedText.string)")
        return (validAttributedText.string, currentAttributedText.length)
    }

    //////////////////////////////////////////////////////////////////////////////////
    // UITextViewDelegate methods
    //////////////////////////////////////////////////////////////////////////////////
    
    func textView(_ textView: UITextView,
        shouldChangeTextInRange range: NSRange,
        replacementText text: String) -> Bool {
            
        // If this is true, then the user just deleted a character by using backspace
        // print("shouldChangeCharactersInRange")
        if (range.length == 1 && text.length == 0) {
            let cursorPosition = range.location //gets cursor current position in the text
            // print("delete, range: \(range), text: \(text), cursorPosition: \(cursorPosition)")
            
            var attrRange: NSRange = NSMakeRange(0,1) //will store the range of the text that holds specific attributes
            let attrs: NSDictionary = self.inputToolbar.contentView.textView.attributedText.attributesAtIndex(
                cursorPosition,
                effectiveRange: &attrRange)
            
            // Check if the attributes of the attributed text in the cursor's current position correspond to what you want to delete as a block
            if let _ = attrs.objectForKey(TappableText.tapAssetId) {
                // creates a new NSAttributed string without the block of text you wanted to delete
                let newStr: NSAttributedString = self.inputToolbar.contentView.textView.attributedText.attributedSubstringFromRange(
                    NSMakeRange(0, attrRange.location))
                self.inputToolbar.contentView.textView.attributedText = newStr  // substitute the attributed text of your UITextView
                return false
            }
        } else if (text.length > 0) {
            // print("insert, range: \(range), text: \(text)")
            self.inputToolbar.contentView.textView.setNormalAttributes()
            
            let cursorPosition = range.location //gets cursor current position in the text
            if cursorPosition < self.inputToolbar.contentView.textView.attributedText.length {
                var attrRange: NSRange = NSMakeRange(0,1) //will store the range of the text that holds specific attributes
                
                let attrs: NSDictionary = self.inputToolbar.contentView.textView.attributedText.attributesAtIndex(
                    cursorPosition,
                    effectiveRange: &attrRange)
                
                if let _ = attrs.objectForKey(TappableText.tapAssetId) {
                    return false
                }
            }
        }
        return true
    }
  
    /*
    func gg_currentlyInputMessageText() -> String {
        return self.inputToolbar.contentView.textView.text
    }
    */
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }

        textView.becomeFirstResponder()

        if (self.automaticallyScrollsToMostRecentMessage) {
            self.scrollToBottomAnimated(true)
        }
        
        let (word, len) = self.gg_currentlyTypedMessageText()
        if let auto = self.autocompleteController {
            if auto.active && word.characters.count >= UserAPI.sharedInstance.settings.minAutocompleteCharacters {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let suggestions = GGWiki.sharedInstance.getCardSuggestions(word, inputLength: len)
                    if suggestions != nil && textView.text != nil && suggestions!.count > 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.autocompleteController?.displaySuggestions(word,
                                suggestions: suggestions!,
                                frame: self.inputToolbar.frame)
                        }
                    }
                }
            } else {
                auto.hide()
            }
        }
    }

    func textViewDidChange(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }
        // if let lastWord = textView.text.componentsSeparatedByCharactersInSet(
        //     NSCharacterSet.whitespaceCharacterSet()).last {
        
        let (word, len) = self.gg_currentlyTypedMessageText()
        // print("editing text \"\(word)\" length: \(word.length), count: \(word.characters.count), min: \(UserAPI.sharedInstance.settings.minAutocompleteCharacters)")
       
        if let auto = self.autocompleteController {
            if auto.active && word.characters.count >= UserAPI.sharedInstance.settings.minAutocompleteCharacters {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let suggestions = GGWiki.sharedInstance.getCardSuggestions(word, inputLength: len)
                    print("Suggestions: \(suggestions?.count)")
                    dispatch_async(dispatch_get_main_queue()) {
                        if let s = suggestions {
                            if s.count > 0 && textView.text != nil && textView.text?.characters.count > 0 {
                                self.autocompleteController?.displaySuggestions(word,
                                    suggestions: s,
                                    frame: self.inputToolbar.frame)
                            } else {
                                self.autocompleteController?.hide()
                            }
                        }
                    }
                }
            } else {
                auto.hide()
            }
        }
        
        self.inputToolbar.toggleSendButtonEnabled()
    }

    func textViewDidEndEditing(textView: UITextView) {
        if (textView != self.inputToolbar.contentView.textView) {
            return
        }

        textView.resignFirstResponder()
        self.autocompleteController?.hide()
    }
    
    func dismissKeyboard() {
        print("dismissKeyboard")
        self.autocompleteController?.hide()
        self.textViewDidEndEditing(self.inputToolbar.contentView.textView)
    }

    // pragma mark - Notifications

     func gg_handleDidChangeStatusBarFrameNotification(notification: NSNotification) {
        print("MVC::gg_handleDidChangeStatusBarFrame")
        if (self.keyboardController!.keyboardIsVisible) {
            self.gg_setToolbarBottomLayoutGuideConstant(CGRectGetHeight(self.keyboardController!.currentKeyboardFrame()))
        }
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
        // print("****************************************************")
        // print("MVC::keyboardDidChangeFrame")
        if (!self.inputToolbar.contentView.textView.isFirstResponder() && self.toolbarBottomLayoutGuide.constant == 0.0) {
            return
        }

        var heightFromBottom: CGFloat = CGRectGetMaxY(self.messageCollectionView.frame) - CGRectGetMinY(keyboardFrame)

        heightFromBottom = max(0.0, heightFromBottom)
        // print(heightFromBottom)

        self.gg_setToolbarBottomLayoutGuideConstant(heightFromBottom)
    }

    func gg_setToolbarBottomLayoutGuideConstant(constant: CGFloat) {
        self.toolbarBottomLayoutGuide.constant = constant
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()

        self.gg_updateCollectionViewInsets()
    }

    func gg_updateKeyboardTriggerPoint() {
        self.keyboardController!.keyboardTriggerPoint = CGPointMake(0.0, CGRectGetHeight(self.inputToolbar.bounds))
    }

    // pragma mark - Gesture recognizers
    func gg_handleInteractivePopGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        print("gg_handleInteractivePopGestrureRecognizer")
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerState.Began:
                if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                    self.snapshotView!.removeFromSuperview()
                }

                self.textViewWasFirstResponderDuringInteractivePop = self.inputToolbar.contentView.textView.isFirstResponder()

                self.keyboardController!.endListeningForKeyboard()

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
                break
            case UIGestureRecognizerState.Changed:
                break
            case UIGestureRecognizerState.Cancelled, UIGestureRecognizerState.Ended,UIGestureRecognizerState.Failed:
                self.keyboardController!.beginListeningForKeyboard()
                if (self.textViewWasFirstResponderDuringInteractivePop) {
                    self.inputToolbar.contentView.textView.becomeFirstResponder()
                }

                if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                    self.snapshotView!.removeFromSuperview()
                }
                break
            default:
                break
        }
    }

    // pragma mark - Input toolbar utilities

    func gg_inputToolbarHasReachedMaximumHeight() -> Bool {
        return CGRectGetMinY(self.inputToolbar.frame) == (self.topLayoutGuide.length + self.topContentAdditionalInset)
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
            if let _ = self.dateForTopLabelAtIndexPath(collectionView, indexPath: indexPath) {
            return MessagesCollectionViewFlowLayout.kMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    func dateForTopLabelAtIndexPath(_ collectionView: UICollectionView, indexPath: NSIndexPath) -> String? {
        let message = self.messages[indexPath.item]
        let date = MessageTimestampFormatter.sharedInstance.relativeDateForDate(message.date)
        if indexPath.item == 0 {
            return date
        } else if indexPath.item < self.messages.count {
            let prevIndex = indexPath.item - 1
            let prevMessage = self.messages[prevIndex]
            
            let prevDate = MessageTimestampFormatter.sharedInstance.relativeDateForDate(prevMessage.date)
           
            if prevDate != date {
                return date
            } else {
                return nil
            }
        }
        return nil
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
        let currentMessage: Message = self.messages[indexPath.item]
        if (currentMessage.senderId == self.senderId) {
            return 0.0
        }
        
        if (indexPath.item - 1 > 0) {
            let previousMessage: Message = self.messages[indexPath.item - 1]
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
        self.dismissKeyboard()
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
        
        let message = self.messages[indexPath.row]
        if message.isMediaMessage {
            if let mivc = self.messageImageViewController, let photoMedia = message.media as? PhotoMediaItem {
                mivc.image = photoMedia.image
                // self.presentViewController(mivc, animated: true, completion: nil)
                self.presentTransparentViewController(mivc, animated: true, completion: nil)
            }
        }
        self.dismissKeyboard()
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
        self.dismissKeyboard()
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
    
    
    func composerTextView(textView: MessageComposerTextView,
        shouldPasteWithSender sender: AnyObject?) -> Bool {
        if ((UIPasteboard.generalPasteboard().image) != nil) {
            // If there's an image in the pasteboard, construct a media item with that image and `send` it.
            let item: PhotoMediaItem = PhotoMediaItem(
                image: UIPasteboard.generalPasteboard().image!,
                delegate: self)
            let message: Message = Message(
                id: XMPPManager.sharedInstance.stream.generateUUID(),
                senderId: self.senderId,
                senderDisplayName: self.senderDisplayName,
                isOutgoing: true,
                date: NSDate(),
                media: item)
            self.messages.append(message)
            self.finishSendingMessage()
            return false
        }
        return true
    }
    
    func autocompleteSelect(
        autocompleteController: MessageAutocompleteController,
        assetSuggestion: AssetAutocompleteSuggestion) {
        let originalText = self.inputToolbar.contentView.textView.attributedText.string
        let replaceBy = min(assetSuggestion.replaceIndex, originalText.characters.count)
        let replaceText = self.inputToolbar.contentView.textView.attributedText.attributedSubstringFromRange(
            NSMakeRange(0, replaceBy))
        /*
        self.inputToolbar.contentView.textView.text = replaceText
        self.inputToolbar.contentView.textView.text.appendContentsOf(assetSuggestion.id)
        */
      
        assert(GGWiki.sharedInstance.cardAssets[assetSuggestion.id] != nil, "Asset \(assetSuggestion.id) not loaded.")
        self.inputToolbar.contentView.textView.attributedText = TappableText.sharedInstance.tappableAttributedString(
            assetSuggestion.id,
            textColor: self.inputToolbar.contentView.textView.textColor!,
            highlightColor: true,
            textFont: GGConfig.messageComposerFont,
            prevAttributedString: replaceText)
        // print(self.inputToolbar.contentView.textView.attributedText)
        self.autocompleteController?.hide()
    }
    
    func redrawMessageMedia() {
        // print("redrawMessageMedia")
        dispatch_async(dispatch_get_main_queue()) {
            if self.messageCollectionView != nil {
                // This method could be called before viewWillLoad / viewDidLoad has initialized the view controller
                // self.messageCollectionView.collectionViewLayout.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
                self.messageCollectionView.reloadData()
                if self.inputToolbar.contentView.textView.isFirstResponder() {
                    self.scrollToBottomAnimated(false)
                } else if let lastIndexPath = self.lastScrollVisibleCellIndexPath {
                    // let scrollPosition: UICollectionViewScrollPosition = (finalCellSize.height > maxHeightForVisibleMessage) ? UICollectionViewScrollPosition.Bottom : UICollectionViewScrollPosition.Top
                    /*
                    print("redraw scroll to last index path \(lastIndexPath)")
                    
                    let scrollPosition = UICollectionViewScrollPosition.Bottom
                    self.messageCollectionView.scrollToItemAtIndexPath(lastIndexPath,
                        atScrollPosition: scrollPosition,
                        animated: false)
                    */
                } else {
                    // print("redrawMessageMedia --> scrollToBottomAnimated")
                    self.scrollToBottomAnimated(false)
                }
            }
        }
    }
   
    var lastScrollVisibleCellIndexPath: NSIndexPath?
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let visibleCells = self.messageCollectionView.visibleCells()
        if let lastVisibleCell = visibleCells.last {
            self.lastScrollVisibleCellIndexPath = self.messageCollectionView.indexPathForCell(lastVisibleCell)
        }
    }
    
    func presentTransparentViewController(
        viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: ((Void) -> Void)?) {
            if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
                self.parentViewController!.navigationController!.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
            } else {
                viewControllerToPresent.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
                // print("presentTransparentViewController")
            }
            
            self.presentViewController(viewControllerToPresent,
                animated: true,
                completion: completion)
    }
    
    
    
}