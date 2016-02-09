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
    XMPPManagerDelegate,
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
                    self.loadArchivedMessagesFromCoreData(true, animated: true)
                }
            }
        }
    }
    var recipientDetails: UIView?
    var photoPicker = UIImagePickerController()
    var imageModelViewController: ImageModalViewController?
    
    var fromId: String {
        get {
            if let recipient = self.recipient {
                if recipient.isGroup {
                    return recipient.jid
                }
            }
            return UserAPI.sharedInstance.jidBareStr
        }
    }
   
    // Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showLoadEarlierMessagesHeader = true
        XMPPMessageManager.sharedInstance.delegate = self
        XMPPManager.sharedInstance.delegate = self
        
        self.photoPicker.delegate = self
        self.messageCollectionView.reloadData()
   
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
        self.initImageModalViewController()
        
        // Initialize refresh control
        let refreshController = UIRefreshControl()
        refreshController.tintColor = UIColor.grayColor()
        refreshController.addTarget(self, action: Selector("refreshControlAction:"), forControlEvents: UIControlEvents.ValueChanged)
        self.messageCollectionView.addSubview(refreshController)
        self.messageCollectionView.alwaysBounceVertical = true
        
        XMPPManager.refresh()
    }
    
    func refreshControlAction(refreshController: UIRefreshControl) {
        // print("refresh")
        if let recipient = self.recipient {
            if let firstMessage = self.messages.first {
                if XMPPMessageManager.sharedInstance.hasMoreMessagesToLoad {
                    var moreMessages = XMPPMessageManager.sharedInstance.loadMoreAchivedMessagesFrom(recipient.jid, firstDate: firstMessage.date, delegate: self)
                    let firstRow = moreMessages.count
                    print("Load \(moreMessages.count) messages")
                    moreMessages.appendContentsOf(self.messages)
                    self.messages = moreMessages
                    self.messageCollectionView.reloadData()
                    let firstIndexPath = NSIndexPath(forRow: firstRow, inSection: 0)
                    self.messageCollectionView.scrollToItemAtIndexPath(firstIndexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                } else {
                    // self.messageCollectionView.reloadData()
                    // refreshController.removeFromSuperview()
                    self.syncEarlierHistoryMessages(refreshController)
                }
            }
        }
        refreshController.endRefreshing()
    }
    
    func syncEarlierHistoryMessages(refreshController: UIRefreshControl) {
        if let recipient = self.recipient {
            if let firstDate = self.messages.first?.date {
                UserAPI.sharedInstance.getHistory(recipient.jid,
                    isGroup: recipient.isGroup,
                    limit: GGConfig.paginationLimit,
                    end: firstDate,
                    delegate: self,
                    completion: { (messages: [Message]?, xmls: [String]?) -> Void in
                    if let msgs = messages, let xmls = xmls {
                        dispatch_async(dispatch_get_main_queue()) {
                            var earlierMessages = [Message]()
                            for i in 0..<msgs.count {
                                let m = msgs[i]
                                let x = xmls[i]
                                if XMPPMessageManager.sharedInstance.archiveMessage(m.id, xmlString: x, date: m.date, outgoing: m.isOutgoing) {
                                    earlierMessages.append(m)
                                }
                            }
                            let firstRow = earlierMessages.count
                            print("Loaded \(msgs.count) earlier messages from history")
                            earlierMessages.appendContentsOf(self.messages)
                            self.messages = earlierMessages
                            
                            self.messageCollectionView.reloadData()
                            let firstIndexPath = NSIndexPath(forRow: firstRow, inSection: 0)
                            self.messageCollectionView.scrollToItemAtIndexPath(firstIndexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                            
                            if firstRow < GGConfig.paginationLimit {
                                refreshController.removeFromSuperview()
                            }
                        }
                    } else {
                        refreshController.removeFromSuperview()
                    }
                })
            } else {
                self.messageCollectionView.reloadData()
                refreshController.removeFromSuperview()
            }
        }
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
                let id = XMPPManager.sharedInstance.stream.generateUUID()
                let message: Message = Message(
                    id: id,
                    toId: recipient.jid,
                    fromId: self.fromId,
                    senderId: UserAPI.sharedInstance.jidBareStr,
                    date: now,
                    media: photoMedia)
           
                message.isComposing = true
                self.appendMessage(recipient.jid, date: now, message: message)
               
                S3PhotoManager.sharedInstance.sendPhoto(id, image: chosenImage, to: recipient.jid)
                
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
        // print("GG::viewWillAppear")
        super.viewWillAppear(animated)
      
        if let recipient = self.recipient {
            self.readIncomingMessages(recipient.jid)
            self.initBackButton()
        }
        
        // self.loadArchivedMessagesFromCoreData(false, animated: true)
        // self.finishReceivingMessageAnimated(false)
        // self.scrollToBottomAnimated(false)
        
        // self.loadLastActivity(false)
        if SettingManager.sharedInstance.tappableMessageText {
            TappableText.sharedInstance.delegate = self
        }
    }
    
    /*
    func loadLastActivity(force: Bool) {
        // Disable last activity
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
    }
    */
    
    func loadArchivedMessagesFromCoreData(sync: Bool, animated: Bool) {
        if let recipient = self.recipient {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                var receipts = [ReadReceipt]()
                (self.messages, receipts) = XMPPMessageManager.sharedInstance.loadArchivedMessagesFrom(
                    jid: recipient.jid,
                    delegate: self
                )
                print("XMPPMessengerManager.loadArchivedMessagesFrom: \(self.messages.count) messages")
                self.readMessagesFromCoreDataReceipts(receipts)
                self.readIncomingMessages(recipient.jid)
                print("XMPPMessengerManager.readIncomingMessages")
                if animated {
                    self.finishReceivingMessageAnimated(false)
                    self.scrollToBottomAnimated(false)
                }
                if sync && self.messages.count == 0 {
                    self.syncHistoryMessages(animated)
                }
            })
        }
    }
   
    func syncHistoryMessages(animated: Bool) {
        if let recipient = self.recipient {
            UserAPI.sharedInstance.getHistory(recipient.jid,
                isGroup: recipient.isGroup,
                limit: GGConfig.paginationLimit,
                end: nil,
                delegate: self,
                completion: { (messages: [Message]?, xmls: [String]?) -> Void in
                if let msgs = messages, let xmls = xmls {
                    dispatch_async(dispatch_get_main_queue()) {
                        print("returned \(msgs.count) messages from archives")
                        // print(xmls)
                        for i in 0..<msgs.count {
                            let m = msgs[i]
                            let x = xmls[i]
                            if XMPPMessageManager.sharedInstance.archiveMessage(m.id, xmlString: x, date: m.date, outgoing: m.isOutgoing) {
                                self.messages.append(m)
                            }
                        }
                        self.messages.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
                        self.readIncomingMessages(recipient.jid)
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
        XMPPManager.sharedInstance.delegate = nil
        
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
        withMessagePacket packet: MessagePacket,
        date: NSDate) {
            
        if let recipient = self.recipient {
            JSQSystemSoundPlayer.jsq_playMessageSentSound()

            // let text = packet.encodedText
            let id = XMPPManager.sharedInstance.stream.generateUUID()
            let message = packet.message(id,
                toId: recipient.jid,
                fromId: self.fromId,
                senderId: UserAPI.sharedInstance.jidBareStr,
                date: date,
                delegate: self)
           
            message.isComposing = true
            self.appendMessage(recipient.jid, date: date, message: message)
         
            XMPPMessageManager.sendMessage(
                id: id,
                message: packet,
                to: recipient.jid,
                date: date,
                isOutgoing: message.isOutgoing,
                isGroup: recipient.isGroup,
                completionHandler: nil)
        
            self.finishSendingMessageAnimated(true)
        }
    }
    
    override func composerTextView(textView: MessageComposerTextView,
        shouldPasteWithSender sender: AnyObject?) -> Bool {
        if let recipient = self.recipient {
            if ((UIPasteboard.generalPasteboard().image) != nil) {
                // If there's an image in the pasteboard, construct a media item with that image and `send` it.
                let item: PhotoMediaItem = PhotoMediaItem(
                    image: UIPasteboard.generalPasteboard().image!,
                    delegate: self)
                let message: Message = Message(
                    id: XMPPManager.sharedInstance.stream.generateUUID(),
                    toId: recipient.jid,
                    fromId: self.fromId,
                    senderId: UserAPI.sharedInstance.jidBareStr,
                    date: NSDate(),
                    media: item)
                self.messages.append(message)
                self.finishSendingMessage()
                return false
            }
        }
        return true
    }
    
    override func didPressEllipsisButton(sender: UIButton) {
        // print("didPressEllipsisButton")
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
                        // GGWiki.sharedInstance.loadAutocompleteAsync(k)
                        // self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(v.iconImage)
                        // self.autocompleteController?.active = true
                }
                alert.addAction(action)
            }
        }
        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
   
    /*
    override func didPressLeftButton(sender: UIButton) {
        // self.inputToolbar.contentView.textView.becomeFirstResponder()
        self.inputToolbar.contentView.textView.placeHolder = NSBundle.gg_localizedStringForKey("new_message")
        self.autocompleteController?.active = false
        self.inputToolbar.contentView.showTextView()
    }
    */
   
    /*
    override func didPressInnerButton(sender: UIButton) {
        if let auto = self.autocompleteController {
            if auto.active {
                self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.defaultKeyboardButtonItem()
                auto.active = false
            } else {
                if let wiki = GGWiki.sharedInstance.getAutocompleteResource() {
                    auto.active = true
                    self.inputToolbar.contentView.leftInnerBarButtonItem = MessageToolbarButtonFactory.customKeyboardButtonItem(wiki.iconImage)
                }
            }
        }
    }
    */
    
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
        /*
        let actionLocation = UIAlertAction(
            title: "Send location",
            style: UIAlertActionStyle.Default) { action -> Void in
        }
        let actionVideo = UIAlertAction(
            title: "Send video",
            style: UIAlertActionStyle.Default) { action -> Void in
        }
        */
        alert.addAction(actionCancel)
        alert.addAction(actionPhoto)
        // alert.addAction(actionLocation)
        // alert.addAction(actionVideo)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        // alert.showFromToolbar(self.inputToolbar)
        // JSQSystemSoundPlayer.jsq_playMessageSentSound()
        // self.finishSendingMessageAnimated(true)
    }
    
    func appendMessage(peerJID: String, date: NSDate, message: Message) {
        self.messages.append(message)
        UserAPI.sharedInstance.newMessage(peerJID, date: date, message: message)
    }
    
    func readMessagesFromCoreDataReceipts(receipts: [ReadReceipt]) {
        print("Read receipts in core data: \(receipts.count)")
        if let recipient = self.recipient {
            for receipt in receipts {
                // print("receipt from \(receipt.from)")
                if recipient.jid == receipt.from || recipient.jid == receipt.to {
                    for msg in self.messages {
                        if receipt.ids.contains(msg.id) {
                            // print("market as read --> \(msg.id)")
                            msg.markAsRead()
                        }
                    }
                }
            }
        }
    }
    
    func readIncomingMessages(from: String) {
        UserAPI.sharedInstance.readAllMessages(from)
        self.initBackButton()
       
        var ids = [String]()
        for msg in self.messages {
            if !msg.isOutgoing {
                if !msg.isRead {
                    ids.append(msg.id)
                    msg.markAsRead()
                }
            }
        }
        print("readIncomingMessages, msgs: \(self.messages.count), read: \(ids.count)")
        if ids.count > 0 {
            XMPPMessageManager.sendReadReceipt(ids, to: from)
        }
    }
    
    func receiveMessage(from: String, message: Message) {
        if let recipient = self.recipient {
            if recipient.jid == from {
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                message.setMediaDelegate(self)
                dispatch_async(dispatch_get_main_queue()) {
                    self.appendMessage(from, date: message.date, message: message)
                    self.finishReceivingMessageAnimated(true)
                    self.readIncomingMessages(recipient.jid)
                }
            }
        }
        self.initBackButton()
    }
    
    func receiveComposingMessage(from: String) {
        if let recipient = self.recipient {
            if recipient.jid == from {
                dispatch_async(dispatch_get_main_queue()) {
                    self.showTypingIndicator = !self.showTypingIndicator
                    self.scrollToBottomAnimated(true)
                }
            }
        }
    }
    
    func receiveReadReceipt(from: String, readReceipt: ReadReceipt) {
        if let recipient = self.recipient {
            if recipient.jid == from {
                print("receivedReadReceipt from \(from)")
                var update = false
                for msg in self.messages {
                    if readReceipt.ids.contains(msg.id) {
                        msg.markAsRead()
                        update = true
                    }
                }
                if update {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.messageCollectionView.reloadData()
                    }
                }
            }
        }
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
        if textView != self.inputToolbar.contentView.textView {
            return
        }
        
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
    
    func didSendMessage(message: XMPPMessage) {
        if let id = message.attributeStringValueForName("id") {
            // print("didSendMessage: \(id)")
           
            var update = false
            for msg in self.messages.reverse() {
                if msg.id == id {
                    msg.isComposing = false
                    update = true
                    break
                }
            }
            if !update {
                let date = NSDate()
                if let message = Message.parseMessageFromElement(message as DDXMLElement, date: date, delegate: self),
                    let recipient = self.recipient {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.appendMessage(recipient.jid, date: date, message: message)
                        self.finishSendingMessageAnimated(true)
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.messageCollectionView.reloadData()
                }
            }
        }
    }
    
    func didFailSendMessage(message: XMPPMessage) {
        if let id = message.attributeStringValueForName("id") {
            print("didFailSendMessage: \(id)")
           
            var update = false
            for msg in self.messages.reverse() {
                if msg.id == id {
                    msg.isFailedToSend = true
                    msg.isComposing = false
                    update = true
                    break
                }
            }
            if update {
                dispatch_async(dispatch_get_main_queue()) {
                    self.messageCollectionView.reloadData()
                }
            }
        }
    }
    
    func resendFailedMessages() {
        if let recipient = self.recipient {
            dispatch_async(dispatch_get_main_queue()) {
                for msg in self.messages {
                    if msg.isFailedToSend {
                        msg.isFailedToSend = false
                        msg.isComposing = true
                    }
                }
                self.messageCollectionView.reloadData()
                XMPPMessageManager.sharedInstance.resendArchivedComposingMessagesFrom(recipient.jid)
            }
        }
    }
    
    func onAuthenticate() {
        self.resendFailedMessages()
    }
  
    /*
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if let recipient = self.recipient {
            if scrollView.contentOffset.y <= 0 && XMPPMessageManager.sharedInstance.hasMoreMessagesToLoad {
                if let firstMessage = self.messages.first {
                    let visibleCells = self.messageCollectionView.visibleCells()
                    
                    print("scrollViewDidScroll y-offset: \(scrollView.contentOffset.y), y-position: \(scrollView.contentOffset.y), index: \(self.lastScrollVisibleCellIndexPath)")
                    var moreMessages = XMPPMessageManager.sharedInstance.loadMoreAchivedMessagesFrom(recipient.jid, firstDate: firstMessage.date, delegate: self)
                    print("Load \(moreMessages.count) messages")
                    moreMessages.appendContentsOf(self.messages)
                    self.messages = moreMessages
                    self.messageCollectionView.reloadData()
                    if let firstIndexPath = self.firstScrollVisibleCellIndexPath {
                        self.messageCollectionView.scrollToItemAtIndexPath(firstIndexPath, atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
                    }
                }
            }
        }
    }
    */
}
