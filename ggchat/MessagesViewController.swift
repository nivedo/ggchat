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
    
    var automaticallyScrollsToMostRecentMessage: Bool
    var outgoingCellIdentifier: String
    var outgoingMediaCellIdentifier: String
    var incomingCellIdentifier: String
    var incomingMediaCellIdentifier: String
    var showTypingIndicator: Bool
    var showLoadEarlierMessagesHeader: Bool
    var topContentAdditionalInset: CGFloat
    var gg_isObserving: Bool
    
    // var toolbarHeightConstraint: NSLayoutConstraint
    // var toolbarBottomLayoutGuide: NSLayoutConstraint
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    var senderId: String
    var senderDisplayName: String
    let incomingBubble = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(
        UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(
        UIColor.lightGrayColor())
    
    var messages = [Message]()
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    func setup() {
        self.senderId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        self.senderDisplayName = UIDevice.currentDevice().identifierForVendor!.UUIDString
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.gg_isObserving = false
        
        // self.toolbarHeightConstraint.constant = self.inputToolbar.preferredDefaultHeight;
        
        self.collectionView?.dataSource = self;
        self.collectionView?.delegate = self;
        
        // self.inputToolbar.delegate = self;
        // self.inputToolbar.contentView.textView.placeHolder = [NSBundle jsq_localizedStringForKey:@"new_message"];
        // self.inputToolbar.contentView.textView.delegate = self;
        
        self.automaticallyScrollsToMostRecentMessage = true
        
        self.outgoingCellIdentifier =
            OutgoingMessagesCollectionViewCell.cellReuseIdentifier()
        self.outgoingMediaCellIdentifier =
            OutgoingMessagesCollectionViewCell.mediaCellReuseIdentifier()
        
        self.incomingCellIdentifier =
            IncomingMessagesCollectionViewCell.cellReuseIdentifier()
        self.incomingMediaCellIdentifier =
            IncomingMessagesCollectionViewCell.mediaCellReuseIdentifier()
        
        // NOTE: let this behavior be opt-in for now
        // [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
        
        self.showTypingIndicator = false
        self.showLoadEarlierMessagesHeader = false
        self.topContentAdditionalInset = 0.0
        
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
   
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func gg_updateCollectionViewInsets() {
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    // UICollectionViewController methods
    //////////////////////////////////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

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
}