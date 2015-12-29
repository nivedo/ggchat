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

    var recipient: RosterUser?
    var recipientDetails: UIView?
    var photoPicker = UIImagePickerController()
    var imageModelViewController: ImageModalViewController?
   
    // Initialization
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        print("GGMessageViewController::viewDidLoad()")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.senderId = XMPPManager.sharedInstance.jid
        self.senderDisplayName = UserAPI.sharedInstance.displayName
        
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
                    isOutgoing: true,
                    date: NSDate(),
                    media: photoMedia)
            
                self.messages.append(message)
               
                S3PhotoManager.sharedInstance.sendPhoto(chosenImage, to: recipient.jid)
                
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
                XMPPLastActivityManager.sendLastActivityQueryToJID(recipient.jid,
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
                    let archiveMessages = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(
                        jid: recipient.jid,
                        mediaCompletion: { (Void) -> Void in
                        self.messageCollectionView.reloadData()
                    })
                    self.messages = archiveMessages as NSArray as! [Message]
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
   
    func didSelectContact(recipient: RosterUser) {
        self.recipient = recipient
       
        if self.recipientDetails == nil {
            self.navigationItem.title = recipient.displayName
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

            let message: Message = Message(
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                isOutgoing: true,
                date: date,
                text: text)
            
            self.messages.append(message)
                
            XMPPMessageManager.sendMessage(text,
                to: recipient.jid,
                completionHandler: nil)
        
            self.finishSendingMessageAnimated(true)
        }
    }

    override func didPressInnerButton(sender: UIButton) {
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
                }
                alert.addAction(action)
            }
        }
        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true, completion: nil)
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
                // print("\(tokens[0]) ? \(self.recipient!.jid)")
                if self.recipient == nil || self.recipient!.jid == tokens[0] {
                    
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    
                    let message = Message(
                        senderId: from,
                        senderDisplayName: UserAPI.sharedInstance.getDisplayName(from),
                        isOutgoing: false,
                        date: NSDate(),
                        text: msg)
                    self.messages.append(message)
                    
                    self.finishReceivingMessageAnimated(true)
                }
            }
        }
    }
    
	func onPhoto(
        sender: XMPPStream,
        didReceivePhoto xmppMessage: XMPPMessage,
        from user: XMPPUserCoreDataStorageObject) {
        // print(message.elementForName("photo"))
        if let photo = xmppMessage.elementForName("body")!.elementForName("photo"),
            let originalKey = photo.elementForName("originalKey")?.stringValue(),
            let thumbnailKey = photo.elementForName("thumbnailKey")?.stringValue() {
            
            if let from: String = xmppMessage.attributeForName("from")?.stringValue() {
                let tokens = from.componentsSeparatedByString("/")
                if self.recipient == nil || self.recipient!.jid == tokens[0] {
                
                // Right recipient
                print("Downloading thumbnail \(thumbnailKey)")
                AWSS3DownloadManager.sharedInstance.download(
                    thumbnailKey,
                    userData: nil,
                    completion: { (fileURL: NSURL) -> Void in
                    
                    let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                    let image = UIImage(data: data)
                    let photoMedia: PhotoMediaItem = PhotoMediaItem(image: image!)
                    let message: Message = Message(
                            senderId: from,
                            senderDisplayName: UserAPI.sharedInstance.getDisplayName(from),
                            isOutgoing: false,
                            date: NSDate(),
                            media: photoMedia)
                        
                    self.messages.append(message)
                    self.finishReceivingMessageAnimated(true)
                        
                    print("Downloading original \(originalKey)")
                    AWSS3DownloadManager.sharedInstance.download(
                        originalKey,
                        userData: nil,
                        completion: { (fileURL: NSURL) -> Void in
                        
                        let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                        let image = UIImage(data: data)
                        message.addMedia(PhotoMediaItem(image: image!))
                        // self.messageCollectionView.reloadData()
                        self.finishReceivingMessageAnimated(true)
                    })
                })
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
        if let imvc = self.imageModelViewController {
            imvc.attributes = attributes
            // print(attributes)
            self.presentTransparentViewController(
                imvc,
                animated: true,
                completion: nil)
        }
        // self.dismissKeyboard()

        /*
        let overlayWindow = UIWindow(frame: self.view.window!.frame)
        overlayWindow.windowLevel = UIWindowLevelAlert
        overlayWindow.rootViewController = self.imageModelViewController
        overlayWindow.makeKeyAndVisible()
        */
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
        
        self.imageModelViewController?.onDismiss = { (sender: AnyObject?) -> Void in
            // print("image modal onDismiss")
            self.scrollToBottomAnimated(false)
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        let range: NSRange = textView.selectedRange
        let cursorPosition = range.location
        if range.length == 0 && cursorPosition < self.inputToolbar.contentView.textView.attributedText.length {
            var attrRange: NSRange = NSMakeRange(0,1)
            let attrs = self.inputToolbar.contentView.textView.attributedText.attributesAtIndex(
                cursorPosition,
                effectiveRange: &attrRange)
            
            if let _ = attrs[TappableText.tapAssetId] {
                self.onTap(attrs)
            }
        }
    }
}
