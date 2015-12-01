//
//  GGMessageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/16/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class GGMessageViewController:
    MessageViewController,
    ContactPickerDelegate,
    XMPPMessageManagerDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIActionSheetDelegate {

    var recipient: XMPPUserCoreDataStorageObject?
    var recipientDetails = UIView?()
    var photoPicker = UIImagePickerController()
   
    // Initialization
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        print("GGMessageViewController::viewDidLoad()")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // self.senderId = Demo.id_chang
        // self.senderDisplayName = Demo.displayName_chang
        self.senderId = XMPPManager.sharedInstance.jid
        self.senderDisplayName = XMPPManager.sharedInstance.displayName
        
        // self.messages.appendContentsOf(GGModelData.sharedInstance.messages)
        
        self.showLoadEarlierMessagesHeader = true
        XMPPMessageManager.sharedInstance.delegate = self
       
        self.photoPicker.delegate = self
       
        self.loadUserHistory()
        self.messageCollectionView.reloadData()
    }

    //////////////////////////////////////////////////////////////////////////////////
    // UIImagePickerControllerDelegate
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            print("didFinishPickingMedia")
            if let recipient = self.recipient {
                // GGSystemSoundPlayer.gg_playMessageSentSound()
                let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
                let photoMedia: PhotoMediaItem = PhotoMediaItem(image: chosenImage)
                let message: Message = Message(
                    senderId: senderId,
                    senderDisplayName: senderDisplayName,
                    date: NSDate(),
                    media: photoMedia)
            
                self.messages.append(message)
               
                // TODO: Image size to big, must send out of band.
                /*
                XMPPMessageManager.sendMessage(
                    "",
                    image: chosenImage,
                    to: recipient.jidStr,
                    completionHandler: nil)
                */
                self.dismissViewControllerAnimated(true, completion: nil)
                self.finishSendingMessageAnimated(true)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        print("GG::viewWillAppear")
        
        super.viewWillAppear(animated)
    }
    
    func loadUserHistory() {
        if let recipient = self.recipient {
            self.navigationItem.title = recipient.displayName
          
            XMPPLastActivityManager.sendLastActivityQueryToJID(recipient.jidStr,
                sender: XMPPManager.sharedInstance.lastActivity) { (response, forJID, error) -> Void in
                let lastActivityResponse = XMPPLastActivityManager.sharedInstance.getLastActivityFrom((response?.lastActivitySeconds())!)
                self.recipientDetails = XMPPLastActivityManager.sharedInstance.addLastActivityLabelToNavigationBar(
                    lastActivityResponse, displayName: recipient.displayName)
                
                if (self.recipientDetails != nil) {
                        self.navigationItem.title = ""
                }
                self.navigationController!.view.addSubview(self.recipientDetails!)
            }
            // Load archive messages
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.messages = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr) as NSArray as! [Message]
                self.finishReceivingMessageAnimated(false)
            })
        } else {
            if self.recipientDetails == nil {
                self.navigationItem.title = "New Message"
            }
            self.messages.appendContentsOf(GGModelData.sharedInstance.messages)
            self.finishReceivingMessageAnimated(false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.recipientDetails?.removeFromSuperview()
    }
   
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        self.recipient = recipient
       
        if self.recipientDetails == nil {
            self.navigationItem.title = recipient.displayName
        }
        
        if !XMPPChatManager.knownUserForJid(jidStr: recipient.jidStr) {
            XMPPChatManager.addUserToChatList(jidStr: recipient.jidStr)
        } else {
            /*
            self.messages = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr) as NSArray as! [Message]
            finishReceivingMessageAnimated(true)
            */
        }
    }
    
    // Action delegates
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didPressSendButton(
        button: UIButton,
        withMessageText text: String,
        senderId: String,
        senderDisplayName: String,
        date: NSDate) {
            
        if let recipient = self.recipient {
            // GGSystemSoundPlayer.gg_playMessageSentSound()
        
            let message: Message = Message(
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                date: date,
                text: text)
        
            self.messages.append(message)
                
            XMPPMessageManager.sendMessage(text,
                image: nil,
                to: recipient.jidStr,
                completionHandler: nil)
        
            self.finishSendingMessageAnimated(true)
        }
    }

    override func didPressAccessoryButton(sender: UIButton) {
        let alert: UIAlertController = UIAlertController(
            title: "Media messages",
            message: "Choose media type",
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        let actionPhoto = UIAlertAction(
            title: "Send photo",
            style: UIAlertActionStyle.Default) { action -> Void in
            self.photoPicker.allowsEditing = false
            self.photoPicker.sourceType = .PhotoLibrary
            self.presentViewController(self.photoPicker, animated: true, completion: nil)
        }
        let actionLocation = UIAlertAction(
            title: "Send location",
            style: UIAlertActionStyle.Default) { action -> Void in
                GGModelData.sharedInstance.addLocationMediaMessageCompletion({
                    self.messageCollectionView.reloadData()
                })
        }
        let actionVideo = UIAlertAction(
            title: "Send video",
            style: UIAlertActionStyle.Default) { action -> Void in
            GGModelData.sharedInstance.addVideoMediaMessage()
        }
        alert.addAction(actionCancel)
        alert.addAction(actionPhoto)
        alert.addAction(actionLocation)
        alert.addAction(actionVideo)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        // alert.showFromToolbar(self.inputToolbar)
        // [JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        self.finishSendingMessageAnimated(true)
    }
    
	func onMessage(
        sender: XMPPStream,
        didReceiveMessage message: XMPPMessage,
        from user: XMPPUserCoreDataStorageObject) {
        if let msg: String = message.elementForName("body")?.stringValue() {
            if let from: String = message.attributeForName("from")?.stringValue() {
                let tokens = from.componentsSeparatedByString("/")
                // print("\(tokens[0]) ? \(self.recipient!.jidStr)")
                if self.recipient == nil || self.recipient!.jidStr == tokens[0] {
                    let message = Message(
                        senderId: from,
                        senderDisplayName: from,
                        date: NSDate(),
                        text: msg)
                    self.messages.append(message)
                    
                    self.finishReceivingMessageAnimated(true)
                }
            }
        }
    }
    
	func onMessage(
        sender: XMPPStream,
        userIsComposing user: XMPPUserCoreDataStorageObject) {
        self.showTypingIndicator = !self.showTypingIndicator
        self.scrollToBottomAnimated(true)
    }
}
