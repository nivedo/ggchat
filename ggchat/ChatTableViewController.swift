//
//  ChatTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class ChatTableViewController:
    UITableViewController,
    UISearchResultsUpdating,
    UserDelegate {

    var searchResultController = UISearchController()
    var filteredChatsList = NSArray()
    
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
        self.tableView.reloadData()
    }
    
    func onAvatarUpdate(jid: String, success: Bool) {
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    func onRosterUpdate(success: Bool) {
        // Don't reloadData on roster update, wait for avatar update.
        // Otherwise, avatars will appear blank.
        /*
        if success {
        dispatch_async(dispatch_get_main_queue()) {
        self.tableView.reloadData()
        }
        }
        */
    }
    
    func onChatsUpdate(success: Bool) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultController.view.removeFromSuperview()
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (self.inSearchMode) {
            let searchPredicate = NSPredicate(format: "jidStr CONTAINS[cd] %@",
                searchController.searchBar.text!)
           
            self.filteredChatsList = XMPPChatManager.getChatsList().filteredArrayUsingPredicate(searchPredicate)
            
            print("updateSearch, active: \(self.searchResultController.active), match: \(self.filteredChatsList.count)")
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
            // return self.inSearchMode ? self.filteredChatsList : UserAPI.sharedInstance.chatsList
            return UserAPI.sharedInstance.chatsList
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
        var msgText: String!
        if chatConversation.lastMessage.isMediaMessage {
            msgText = "\(displayName) sent a media item."
        } else {
            msgText = chatConversation.lastMessage.displayText
        }
        let date = MessageTimestampFormatter.sharedInstance.timestampForDate(chatConversation.lastMessage.date)
       
        cell.cellTopLabel.attributedText = NSAttributedString(string: displayName)
        cell.cellBottomLabel.attributedText = NSAttributedString(string: msgText)
        cell.cellCornerLabel.attributedText = NSAttributedString(string: date)
       
        let avatar = UserAPI.sharedInstance.getAvatarImage(chatConversation.peerJID)
        cell.avatarImageView.image = avatar.avatarImage
        cell.avatarImageView.highlightedImage = avatar.avatarHighlightedImage
        
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
                        XMPPChatManager.removeUserAtIndexPath(indexPath)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
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
            let user = sender as! XMPPUserCoreDataStorageObject
            if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                print("ContactPickerDelege!")
                // cpd.didSelectContact(user)
            }
        }
    }
    
    /*
    func tableView(tableView: UITableView,
        avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        // return GGModelData.sharedInstance.getAvatar(Demo.id_jobs)
        let user = XMPPChatManager.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        return GGModelData.sharedInstance.getAvatar(user.jidStr)
    }
    */
    
    func onRosterContentChanged(controller: NSFetchedResultsController) {
        print("onRosterContentChanged")
        self.tableView.reloadData()
    }
}
