//
//  ChatTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import CustomBadge

class ChatTableViewController:
    UITableViewController,
    UISearchResultsUpdating,
    XMPPMessageManagerDelegate,
    UserDelegate {

    var searchResultController = UISearchController()
    var filteredChatsList = [ChatConversation]()
    var chatsList = [ChatConversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Chats"
        
        self.searchResultController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false // true
            controller.searchBar.sizeToFit()
            controller.searchBar.placeholder = "Search for messages or usernames"
            controller.searchBar.searchBarStyle = UISearchBarStyle.Minimal
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
   
        UserAPI.sharedInstance.delegate = self
        XMPPMessageManager.sharedInstance.delegate = self
        // self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        UserAPI.sharedInstance.delegate = self
        XMPPMessageManager.sharedInstance.delegate = self
        
        self.chatsList = UserAPI.sharedInstance.chatsList
        print("Chats::viewWillAppear --> \(self.chatsList.count)")
        TabBarController.updateChatsBar(self.tabBarController)
        self.tableView.reloadData()
        
        ConnectionManager.checkConnection(self)
    }
    
    func onAvatarUpdate(jid: String, success: Bool) {
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    func onRosterUpdate(success: Bool) {
        // Nothing to do
    }
    
    func onChatsUpdate(success: Bool) {
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.chatsList = UserAPI.sharedInstance.chatsList
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultController.view.removeFromSuperview()
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (self.inSearchMode) {
            let searchString = searchController.searchBar.text!.lowercaseString
            self.filteredChatsList = self.chatsList.filter { chat in
                if let user = UserAPI.sharedInstance.rosterMap[chat.peerJID] {
                    return user.displayName.lowercaseString.containsString(searchString)
                } else {
                    return false
                }
            }
        }
        self.tableView.reloadData()
    }
    
    var inSearchMode: Bool {
        get {
            return self.searchResultController.active
                && self.searchResultController.searchBar.text!.characters.count > 0
        }
    }
    
    var dataList: [ChatConversation] {
        get {
            if self.inSearchMode {
                return self.filteredChatsList
            } else {
                return self.chatsList
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            ChatTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ChatTableViewCell

        // Configure the cell...
        let chatConversation = self.dataList[indexPath.row]
      
        let displayName = UserAPI.sharedInstance.getDisplayName(chatConversation.peerJID)
        let msgText = chatConversation.lastMessage.displayText
        let date = MessageTimestampFormatter.sharedInstance.conciseTimestampForDate(chatConversation.lastMessage.date)
       
        cell.cellTopLabel.attributedText = NSAttributedString(string: displayName)
        cell.cellBottomLabel.attributedText = NSAttributedString(string: msgText)
        cell.cellCornerLabel.attributedText = NSAttributedString(string: date)
       
        let avatar = UserAPI.sharedInstance.getAvatarImage(chatConversation.peerJID)
        cell.avatarImageView.image = avatar.avatarImage
        // cell.avatarImageView.highlightedImage = avatar.avatarHighlightedImage
        
        if chatConversation.unreadCount == 0 {
            // cell.badgeImageView.image = nil
            cell.badge = nil
        } else {
            let badge = "\(chatConversation.unreadCount)"
            cell.badge = CustomBadge(string: badge)
            // cell.badgeImageView.image = MessageAvatarImageFactory.badgeImageWithNumber(badge)
        }
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if !self.inSearchMode {
            if editingStyle == .Delete {
                // Delete the row from the data source
                let refreshAlert = UIAlertController(
                    title: "",
                    message: "Are you sure you want to clear the entire message history? \n This cannot be undone.",
                    preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                refreshAlert.addAction(UIAlertAction(title: "Clear message history",
                    style: .Destructive,
                    handler: { (action: UIAlertAction!) in
                        let chat = self.dataList[indexPath.row]
                        UserAPI.sharedInstance.deleteHistory(chat.peerJID, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                            print("deleteHistory --> \(jsonBody)")
                            dispatch_async(dispatch_get_main_queue()) {
                                if let _ = jsonBody {
                                    self.chatsList = UserAPI.sharedInstance.removeChatConversation(chat.peerJID)
                                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                                    XMPPMessageManager.sharedInstance.clearCoreDataFor(chat.peerJID)
                                } else {
                                    let alert = UIAlertView()
                                    alert.title = "Alert"
                                    alert.message = "Unable to delete message history"
                                    alert.addButtonWithTitle("OK")
                                    alert.show()                                }
                                }
                            }
                        )
                }))
                
                refreshAlert.addAction(UIAlertAction(title: "Cancel",
                    style: .Cancel,
                    handler: { (action: UIAlertAction!) in
                }))
                
                self.presentViewController(refreshAlert, animated: true, completion: nil)
                
            } else if editingStyle == .Insert {
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("clicked \(indexPath)")
        
        let chatConversation = self.dataList[indexPath.row]
        self.searchResultController.searchBar.resignFirstResponder()
        self.searchResultController.active = false
        
        self.performSegueWithIdentifier("chats.to.messages", sender: chatConversation)
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "chats.to.messages") {
            if let chatConversation = sender as? ChatConversation, let user = UserAPI.sharedInstance.rosterMap[chatConversation.peerJID] {
                if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                    print("segue --> chats.to.messages, \(user.displayName)")
                    cpd.didSelectContact(user)
                }
            }
        }
    }
    
    func receiveComposingMessage(from: String) {
        // Do nothing for chat view
    }
    
    func receiveMessage(from: String, message: Message) {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
            TabBarController.incrementChatsBadge(self.tabBarController)
        }
    }
    
    func receiveReadReceipt(from: String, readReceipt: ReadReceipt) {
        
    }
}
