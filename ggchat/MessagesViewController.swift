//
//  MessagesViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController {

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
    
    
    var messages = [Message]()
    
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
    
    func setup() {
        self.senderId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        self.senderDisplayName = UIDevice.currentDevice().identifierForVendor!.UUIDString
    }
    
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
     func collectionView(collectionView: MessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> MessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
     func collectionView(collectionView: MessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> MessageAvatarImageDataSource! {
        return nil
    }
    
}
