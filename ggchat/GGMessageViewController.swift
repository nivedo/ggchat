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
    UIActionSheetDelegate {

    var recipient: XMPPUserCoreDataStorageObject?
   
    // Initialization
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        print("GGMessageViewController::viewDidLoad()")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // self.senderId = Demo.id_chang
        // self.senderDisplayName = Demo.displayName_chang
        self.senderId = XMPPManager.senderId
        self.senderDisplayName = XMPPManager.senderDisplayName
        
        self.showLoadEarlierMessagesHeader = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let recipient = self.recipient {
            self.navigationItem.title = recipient.displayName
        } else {
            // self.navigationItem.title = "New Message"
            self.navigationItem.title = self.senderDisplayName
        }
    }
   
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        self.recipient = recipient
        
        self.navigationItem.title = recipient.displayName
       
        /*
        if !OneChats.knownUserForJid(jidStr: recipient.jidStr) {
            OneChats.addUserToChatList(jidStr: recipient.jidStr)
        } else {
            messages = OneMessage.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr)
            finishReceivingMessageAnimated(true)
        }
        */
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
        // GGSystemSoundPlayer.gg_playMessageSentSound()
    
        let message: Message = Message(
            senderId: senderId,
            senderDisplayName: senderDisplayName,
            date: date,
            text: text)
    
        GGModelData.sharedInstance.messages.append(message)
            
        // TEMP: Test xmpp
        let test_jid = "sjobs@chat.blub.io"
        XMPPMessageManager.sendMessage(text, to: test_jid, completionHandler: nil)
    
        self.finishSendingMessageAnimated(true)
    }

    override func didPressAccessoryButton(sender: UIButton) {
        /*
        let sheet: UIActionSheet = UIActionSheet(
            title: "Media messages",
            delegate: self,
            cancelButtonTitle: "Cancel",
            destructiveButtonTitle: nil,
            otherButtonTitles: "Send photo", "Send location", "Send video")
        */
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
            GGModelData.sharedInstance.addPhotoMediaMessage()
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
}
