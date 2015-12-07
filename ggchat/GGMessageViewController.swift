//
//  GGMessageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/16/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import JSQSystemSoundPlayer

class GGMessageViewController:
    MessageViewController,
    ContactPickerDelegate,
    XMPPMessageManagerDelegate,
    TappableTextDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIActionSheetDelegate {

    var recipient: XMPPUserCoreDataStorageObject?
    var recipientDetails: UIView?
    var photoPicker = UIImagePickerController()
    var imageModelViewController: ImageModalViewController?
   
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
       
        self.loadUserHistory(true, loadLastActivity: true)
        self.messageCollectionView.reloadData()
   
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
        self.initImageModalViewController()
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
        loadUserHistory(false, loadLastActivity: false)
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
    }
    
    func loadUserHistory(loadArchiveMessages: Bool, loadLastActivity: Bool) {
        if let recipient = self.recipient {
            self.navigationItem.title = recipient.displayName
         
            if self.recipientDetails == nil || loadLastActivity {
                XMPPLastActivityManager.sendLastActivityQueryToJID(recipient.jidStr,
                    sender: XMPPManager.sharedInstance.lastActivity) { (response, forJID, error) -> Void in
                    if let lastActivitySeconds = response?.lastActivitySeconds() {
                        let lastActivityResponse = XMPPLastActivityManager.sharedInstance.getLastActivityFrom(lastActivitySeconds)
                        
                        for subview: UIView in self.navigationController!.view.subviews as [UIView] {
                            if subview == self.recipientDetails {
                                subview.removeFromSuperview()
                            }
                        }
                        self.recipientDetails = XMPPLastActivityManager.sharedInstance.addLastActivityLabelToNavigationBar(
                            lastActivityResponse, displayName: recipient.displayName)
                        if (self.recipientDetails != nil) {
                            self.navigationItem.title = ""
                            
                            self.navigationController!.view.addSubview(
                                self.recipientDetails!)
                        }
                        // print(self.recipientDetails)
                    }
                }
            }
            
            // Load archive messages
            if loadArchiveMessages {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.messages = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr) as NSArray as! [Message]
                    self.finishReceivingMessageAnimated(false)
                })
            }
        } else {
            if self.recipientDetails == nil {
                self.navigationItem.title = "New Message"
            }
            self.messages.appendContentsOf(GGModelData.sharedInstance.messages)
            self.finishReceivingMessageAnimated(false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("GG::viewWillDisappear")
        self.recipientDetails?.removeFromSuperview()
        
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = nil
        }
        
        super.viewWillDisappear(animated)
    }
   
    /*
    override func didMoveToParentViewController(parent: UIViewController?) {
        self.recipientDetails?.removeFromSuperview()
    }
    */
   
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
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
       
            var text_ = text
            if SettingManager.sharedInstance.tappableMessageText {
                let attributedText = TappableText.sharedInstance.tappableAttributedString(
                    text,
                    textColor: UIColor.darkGrayColor(),
                    attributes: nil,
                    brackets: true)
                text_ = attributedText.string.capitalizedString
            }
            let message: Message = Message(
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                date: date,
                text: text_)
            
            self.messages.append(message)
                
            XMPPMessageManager.sendMessage(text_,
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
        // JSQSystemSoundPlayer.jsq_playMessageSentSound()
        // self.finishSendingMessageAnimated(true)
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
                    
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    
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
   
    func onTap(attributes: [String: AnyObject] ) {
        self.dismissKeyboard()
        if let imvc = self.imageModelViewController {
            imvc.attributes = attributes
            // print(attributes)
            self.presentTransparentViewController(
                imvc,
                animated: true,
                completion: nil)
        }
    }
    func onTapCatchAll() {
        self.dismissKeyboard()
    }
    
    func presentTransparentViewController(
        viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: ((Void) -> Void)?) {
        if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
            self.parentViewController!.navigationController!.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        } else {
            viewControllerToPresent.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        }
        
        self.presentViewController(viewControllerToPresent,
            animated: true,
            completion: completion)
    }
    
    func initImageModalViewController() {
        let storyboardName: String = "Main"
        let storyboard: UIStoryboard = UIStoryboard(name: storyboardName, bundle: nil)
        self.imageModelViewController = storyboard.instantiateViewControllerWithIdentifier("Message Image Model View Controller") as? ImageModalViewController
    }
}
