//
//  MessagesViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesViewControllerTemp: UICollectionViewController {

    var collectionView: MessagesCollectionView?
    // var inputToolbar: MessagesInputToolbar
    // var keyboardContorller: MessagesKeyboardController
    var senderDisplayName: String
    var senderId: String
    var automaticallyScrollsToMostRecentMessage: Bool
    var outgoingCellIdentifier: String
    var outgoingMediaCellIdentifier: String
    var incomingCellIdentifier: String
    var incomingMediaCellIdentifier: String
    var showTypingIndicator: Bool
    var showLoadEarlierMessagesHeader: Bool
    var topContentAdditionalInset: CGFloat
    var gg_isObserving: Bool
   
    let incomingBubble = MessageBubbleImageFactory().incomingMessagesBubbleImageWithColor(
        UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = MessageBubbleImageFactory().outgoingMessagesBubbleImageWithColor(
        UIColor.lightGrayColor())
    
    var messages = [Message]()
   
    
    var toolbarHeightConstraint: NSLayoutConstraint
    var toolbarBottomLayoutGuide: NSLayoutConstraint
    
    func addDemoMessages() {
        for i in 1...10 {
            let sender = (i%2 == 0) ? "Server" : self.senderId
            let messageContent = "Message nr. \(i)"
            let message = Message(senderId: sender, senderDisplayName: sender, text: messageContent)
            self.messages += [message]
        }
        self.reloadMessagesView()
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
    }
    
    func gg_configureMessagesViewController() {
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.gg_isObserving = false
        
        // self.toolbarHeightConstraint.constant = self.inputToolbar.preferredDefaultHeight;
        
        self.collectionView?.dataSource = self;
        self.collectionView?.delegate = self;
        
        // self.inputToolbar.delegate = self;
        // self.inputToolbar.contentView.textView.placeHolder = [NSBundle jsq_localizedStringForKey:@"new_message"];
        // self.inputToolbar.contentView.textView.delegate = self;
        
        self.automaticallyScrollsToMostRecentMessage = true
        
        self.outgoingCellIdentifier = [JSQMessagesCollectionViewCellOutgoing cellReuseIdentifier];
        self.outgoingMediaCellIdentifier = [JSQMessagesCollectionViewCellOutgoing mediaCellReuseIdentifier];
        
        self.incomingCellIdentifier = [JSQMessagesCollectionViewCellIncoming cellReuseIdentifier];
        self.incomingMediaCellIdentifier = [JSQMessagesCollectionViewCellIncoming mediaCellReuseIdentifier];
        
        // NOTE: let this behavior be opt-in for now
        // [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
        
        self.showTypingIndicator = false
        self.showLoadEarlierMessagesHeader = false
        self.topContentAdditionalInset = 0.0
        
        // self.gg_updateCollectionViewInsets()
        
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
    
    func setup() {
        self.senderId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        self.senderDisplayName = UIDevice.currentDevice().identifierForVendor!.UUIDString
    }
    
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.gg_configureMessagesViewController()
        
        // Do any additional setup after loading the view.
        self.setup()
        self.addDemoMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK - Data Source
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
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
