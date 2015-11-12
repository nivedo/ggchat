//
//  MessagesViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/11/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MessagesViewController: UICollectionViewController {

    //////////////////////////////////////////////////////////////////////////////////////
    // Properties
    //////////////////////////////////////////////////////////////////////////////////////
    var automaticallyScrollsToMostRecentMessage: Bool = true
    var outgoingCellIdentifier: String = OutgoingMessagesCollectionViewCell.cellReuseIdentifier()
    var outgoingMediaCellIdentifier: String = OutgoingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    var incomingCellIdentifier: String = IncomingMessagesCollectionViewCell.cellReuseIdentifier()
    var incomingMediaCellIdentifier: String = IncomingMessagesCollectionViewCell.mediaCellReuseIdentifier()
    var showTypingIndicator: Bool = false
    var showLoadEarlierMessagesHeader: Bool = false
    var topContentAdditionalInset: CGFloat = 0.0
    var gg_isObserving: Bool = false
    
    // var toolbarHeightConstraint: NSLayoutConstraint
    // var toolbarBottomLayoutGuide: NSLayoutConstraint
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    var senderId: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
    var senderDisplayName: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
    let incomingBubble = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(
        UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(
        UIColor.lightGrayColor())
    var outgoingBubbleImage: MessageBubbleImage = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.gg_messageBubbleLightGrayColor())
    var incomingBubbleImage: MessageBubbleImage = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.gg_messageBubbleGreenColor())
    
    var messages = [Message]()
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    func setup() {
        self.messages.appendContentsOf(GGModelData.sharedInstance.messages)
        self.view.backgroundColor = UIColor.whiteColor()
        
        // self.toolbarHeightConstraint.constant = self.inputToolbar.preferredDefaultHeight;
        
        self.collectionView?.dataSource = self;
        self.collectionView?.delegate = self;
        
        // self.inputToolbar.delegate = self;
        // self.inputToolbar.contentView.textView.placeHolder = [NSBundle jsq_localizedStringForKey:@"new_message"];
        // self.inputToolbar.contentView.textView.delegate = self;
        
        // NOTE: let this behavior be opt-in for now
        // [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
        
        self.gg_updateCollectionViewInsets()
        
        // Don't set keyboardController if client creates custom content view via -loadToolbarContentView
        /*
        if (self.inputToolbar.contentView.textView != nil) {
        self.keyboardController = [[JSQMessagesKeyboardController alloc] initWithTextView:self.inputToolbar.contentView.textView
        contextView:self.view
        panGestureRecognizer:self.collectionView.panGestureRecognizer
        delegate:self];
        }
        */
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // UICollectionViewController utilities
    //////////////////////////////////////////////////////////////////////////////////////
    
    func gg_updateCollectionViewInsets() {
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    // UICollectionViewController methods
    //////////////////////////////////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        print("MessagesViewController::viewDidLoad()")
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.registerClass(MessagesCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

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

    //////////////////////////////////////////////////////////////////////////////////////
    // MARK: UICollectionViewDataSource
    //////////////////////////////////////////////////////////////////////////////////////

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    
        // Configure the cell
    
        return cell
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

    //////////////////////////////////////////////////////////////////////////////////////
    // MARK - Data Source
    //////////////////////////////////////////////////////////////////////////////////////

    func collectionView(collectionView: MessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> MessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
     func collectionView(collectionView: MessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        self.messages.removeAtIndex(indexPath.row)
    }
    
     func collectionView(collectionView: MessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> MessageBubbleImage! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
     func collectionView(collectionView: MessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> MessageAvatarImage! {
        return nil
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    func collectionView(collectionView: MessagesCollectionView, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageBubbleImage {
        /**
        *  You may return nil here if you do not want bubbles.
        *  In this case, you should set the background color of your collection view cell's textView.
        *
        *  Otherwise, return your previously created bubble image data objects.
        */
        let message: Message = self.messages[indexPath.item]
    
        if (message.senderId == self.senderId) {
            return self.outgoingBubbleImage
        }
        
        return self.incomingBubbleImage
    }
    
    func collectionView(collectionView: MessagesCollectionView, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        /**
        *  Return `nil` here if you do not want avatars.
        *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
        *
        *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        *
        *  It is possible to have only outgoing avatars or only incoming avatars, too.
        */
        
        /**
        *  Return your previously created avatar image data objects.
        *
        *  Note: these the avatars will be sized according to these values:
        *
        *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
        *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
        *
        *  Override the defaults in `viewDidLoad`
        */
        let message: Message = self.messages[indexPath.item]
    
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
        
        return GGModelData.sharedInstance.avatars[message.senderId];
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        /**
        *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
        *  The other label text delegate methods should follow a similar pattern.
        *
        *  Show a timestamp for every 3rd message
        */
        if (indexPath.item % 3 == 0) {
            let message: Message = self.messages[indexPath.item]
            // return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
            return NSAttributedString(string: message.senderId)
        }
        return nil;
    }
    
    func collectionView(collectionView: MessagesCollectionView, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        let message: Message = self.messages[indexPath.item]
        
        /**
        *  iOS7-style sender name labels
        */
        if (message.senderId == self.senderId) {
            return nil
        }
        
        if (indexPath.item - 1 > 0) {
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
        return nil;
    }
}
