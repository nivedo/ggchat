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

    var recipient: RosterUser? {
        didSet {
            print("set recipient --> \(self.recipient?.displayName)")
            if let recipient = self.recipient {
                self.navigationItem.title = recipient.displayName
                if !recipient.isEqual(oldValue) {
                    self.loadArchivedMessagesFromCoreData(true, animated: false)
                }
            }
        }
    }
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
        // GGWiki.sharedInstance.delegate = self
      
        self.loadArchivedMessagesFromCoreData(false, animated: false)
        self.loadLastActivity(true)
        self.messageCollectionView.reloadData()
   
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
        self.initImageModalViewController()
    }
    
    func didSendMessage(sender: XMPPStream, message: XMPPMessage) {
        // self.loadArchivedMessagesFromCoreData(false, animated: true)
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
                let photoMedia: PhotoMediaItem = PhotoMediaItem(image: chosenImage, delegate: self)
                let now = NSDate()
                let message: Message = Message(
                    senderId: senderId,
                    senderDisplayName: senderDisplayName,
                    isOutgoing: true,
                    date: now,
                    media: photoMedia)
            
                self.appendMessage(recipient.jid, date: now, message: message)
               
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
        
        // self.loadArchivedMessagesFromCoreData(false, animated: true)
        // self.finishReceivingMessageAnimated(false)
        // self.scrollToBottomAnimated(false)
        
        self.loadLastActivity(false)
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
    }
    
    func loadLastActivity(force: Bool) {
        // Disable last activity
        /*
        if let recipient = self.recipient {
            self.navigationItem.title = recipient.displayName
         
            if self.recipientDetails == nil || force {
                XMPPLastActivityManager.sendLastActivityQueryToJID(recipient.jid,
                    sender: XMPPManager.sharedInstance.lastActivity) { (response, forJID, error) -> Void in
                    if let lastActivitySeconds = response?.lastActivitySeconds() {
                        let lastActivityResponse = XMPPLastActivityManager.sharedInstance.getLastActivityFrom(lastActivitySeconds)
                       
                        if let navController = self.navigationController {
                            for subview: UIView in navController.view.subviews as [UIView] {
                                if subview == self.recipientDetails {
                                    subview.removeFromSuperview()
                                }
                            }
                        }
                        self.recipientDetails = XMPPLastActivityManager.sharedInstance.addLastActivityLabelToNavigationBar(
                            lastActivityResponse, displayName: recipient.displayName)
                        if (self.recipientDetails != nil) {
                            if let navController = self.navigationController {
                                self.navigationItem.title = ""
                                navController.view.addSubview(self.recipientDetails!)
                            }
                        }
                        // print(self.recipientDetails)
                    }
                }
            }
        }
        */
    }
    
    func loadArchivedMessagesFromCoreData(sync: Bool, animated: Bool) {
        if let recipient = self.recipient {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.messages = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(
                    jid: recipient.jid,
                    delegate: self
                )
                if animated {
                    self.finishReceivingMessageAnimated(false)
                    self.scrollToBottomAnimated(false)
                }
                if sync {
                    self.syncArchivedMessages(animated)
                }
            })
        }
    }
    
    func syncArchivedMessages(animated: Bool) {
        if let recipient = self.recipient {
            var syncNeeded = true
            if let lastArchivedMessageId = self.messages.last?.id {
                if let chatConversation = UserAPI.sharedInstance.chatsMap[recipient.jid], let lastServerMessageId = chatConversation.lastMessage.id {
                    syncNeeded = (lastArchivedMessageId != lastServerMessageId)
                }
            }
            
            if syncNeeded {
                self.syncHistoryMessages(animated)
            } else {
                print("sync NOT NEEDED for \(recipient.jid)")
            }
        }
    }
    
    func syncHistoryMessages(animated: Bool) {
        if let recipient = self.recipient {
            let lastMessage = self.messages.last
            let lastTimestamp = self.messages.last?.date
            let lastId = self.messages.last?.id
            var limit: Int? = nil
            if lastMessage == nil {
                limit = 20
            }
            let date = self.messages.last?.date
            print("sync message history from \(date), msg: \(self.messages.last?.displayText), id: \(lastId), time: \(lastTimestamp)")
            UserAPI.sharedInstance.getHistory(recipient.jid,
                limit: limit,
                end: date,
                delegate: self,
                completion: { (messages: [Message]?, xmls: [String]?) -> Void in
                if let msgs = messages, let xmls = xmls {
                    dispatch_async(dispatch_get_main_queue()) {
                        print("returned \(msgs.count) messages from archives")
                        // print(xmls)
                        for i in 0..<msgs.count {
                            let m = msgs[i]
                            let x = xmls[i]
                            // print(m.date)
                            if (lastId == nil || lastId! != m.id) &&
                                (lastTimestamp == nil || m.date.compare(lastTimestamp!) == NSComparisonResult.OrderedDescending) {
                                self.messages.append(m)
                                print("archiving message \(m.displayText)")
                                XMPPMessageManager.sharedInstance.archiveMessage(x, date: m.date, outgoing: m.isOutgoing)
                            }
                        }
                        if animated {
                            self.finishReceivingMessageAnimated(false)
                            self.scrollToBottomAnimated(false)
                        }
                    }
                }
            })
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("GG::viewWillDisappear")
        self.recipientDetails?.removeFromSuperview()
        
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = nil
        }
        // GGWiki.sharedInstance.delegate = nil
        
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

            var message: Message!
            if let asset = AssetManager.getSingleEncodedAsset(text) {
                let wikiMedia: WikiMediaItem = WikiMediaItem(imageURL: asset.url, delegate: self)
                message = Message(
                    senderId: senderId,
                    senderDisplayName: senderDisplayName,
                    isOutgoing: XMPPManager.sharedInstance.isOutgoingJID(senderId),
                    date: NSDate(),
                    media: wikiMedia,
                    text: text)
            }
            
            if message == nil {
                message = Message(
                    senderId: senderId,
                    senderDisplayName: senderDisplayName,
                    isOutgoing: true,
                    date: date,
                    text: text)
            }
            
            self.appendMessage(recipient.jid, date: date, message: message)
         
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
                        
                    self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(v.iconImage)
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
                /*
                GGModelData.sharedInstance.addLocationMediaMessageCompletion({
                    self.messageCollectionView.reloadData()
                })
                */
        }
        let actionVideo = UIAlertAction(
            title: "Send video",
            style: UIAlertActionStyle.Default) { action -> Void in
            // GGModelData.sharedInstance.addVideoMediaMessage()
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
        // from user: XMPPUserCoreDataStorageObject) {
        from user: RosterUser) {
        if let msg: String = message.elementForName("body")?.stringValue() {
            if let from: String = message.attributeForName("from")?.stringValue() {
                let fromBare = UserAPI.stripResourceFromJID(from)
                // print("\(tokens[0]) ? \(self.recipient!.jid)")
                if let recipient = self.recipient {
                    if recipient.jidBare == fromBare {
                    
                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                        let now = NSDate()
                        
                        var message: Message!
                        if let asset = AssetManager.getSingleEncodedAsset(msg) {
                            let wikiMedia: WikiMediaItem = WikiMediaItem(imageURL: asset.url, delegate: self)
                            message = Message(
                                senderId: fromBare,
                                senderDisplayName: UserAPI.sharedInstance.getDisplayName(fromBare),
                                isOutgoing: false,
                                date: now,
                                media: wikiMedia,
                                text: msg)
                        }
                
                        if message == nil {
                            message = Message(
                                senderId: fromBare,
                                senderDisplayName: UserAPI.sharedInstance.getDisplayName(fromBare),
                                isOutgoing: false,
                                date: now,
                                text: msg)
                        }
                        
                        self.appendMessage(fromBare, date: now, message: message)
                        
                        self.finishReceivingMessageAnimated(true)
                    }
                }
            }
        }
    }
    
    func appendMessage(peerJID: String, date: NSDate, message: Message) {
        self.messages.append(message)
        UserAPI.sharedInstance.newMessage(peerJID, date: date, message: message)
    }
    
	func onPhoto(
        sender: XMPPStream,
        didReceivePhoto xmppMessage: XMPPMessage,
        // from user: XMPPUserCoreDataStorageObject) {
        from user: RosterUser) {
        if let photo = xmppMessage.elementForName("body")!.elementForName("photo"),
            let originalKey = photo.elementForName("originalKey")?.stringValue(),
            let thumbnailKey = photo.elementForName("thumbnailKey")?.stringValue() {
            
            if let fromRaw: String = xmppMessage.attributeForName("from")?.stringValue() {
                let from = UserAPI.stripResourceFromJID(fromRaw)
                if self.recipient == nil || self.recipient!.jid == UserAPI.stripResourceFromJID(from) {
                    let photoMedia: PhotoMediaItem = PhotoMediaItem(
                        thumbnailKey: thumbnailKey,
                        originalKey: originalKey,
                        delegate: self)
                    let now = NSDate()
                    let message: Message = Message(
                        senderId: from,
                        senderDisplayName: UserAPI.sharedInstance.getDisplayName(from),
                        isOutgoing: false,
                        date: now,
                        media: photoMedia)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.appendMessage(from, date: now, message: message)
                        self.finishReceivingMessageAnimated(true)
                    }
                }
            }
        }
    }
    
	func onMessage(
        sender: XMPPStream,
        // userIsComposing user: XMPPUserCoreDataStorageObject) {
        userIsComposing user: RosterUser) {
        self.showTypingIndicator = !self.showTypingIndicator
        self.scrollToBottomAnimated(true)
    }
   
    func onTap(attributes: [String: AnyObject] ) {
        if let imvc = self.imageModelViewController {
            imvc.attributes = attributes
            
            if self.inputToolbar.contentView.textView.isFirstResponder() {
                imvc.callDismiss = true
            }
            
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
            print("presentTransparentViewController")
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
            
            if let _ = attrs[TappableText.tapAssetId], let tappable = attrs[TappableText.tapAttributeKey] as? Bool {
                if tappable {
                    self.onTap(attrs)
                }
            }
        }
    }
}
