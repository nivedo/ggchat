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
    XMPPRosterManagerDelegate {

    var searchResultController = UISearchController()
    
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
        
        XMPPRosterManager.sharedInstance.delegate = self
        XMPPManager.sharedInstance.connect(
            username: nil,
            password: nil,
            connectCompletionHandler: nil,
            authenticateCompletionHandler: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        XMPPRosterManager.sharedInstance.delegate = nil
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        // return GGModelData.sharedInstance.chats.count
        return XMPPChatManager.getChatsList().count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            ChatTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ChatTableViewCell

        // Configure the cell...
        let user = XMPPChatManager.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        cell.cellTopLabel.attributedText = NSAttributedString(string: user.displayName)
        cell.cellBottomLabel.attributedText = NSAttributedString(string: user.jidStr)
        
        /*
        let chat = GGModelData.sharedInstance.chats[indexPath.row]

        cell.cellTopLabel.attributedText = NSAttributedString(string: chat.chatDisplayName)
        cell.cellBottomLabel.attributedText = NSAttributedString(string: chat.recentMessage)
        cell.cellCornerLabel.attributedText = NSAttributedString(string: chat.recentUpdateTime)
        */
        
        let needsAvatar: Bool = true
        if (needsAvatar) {
            let avatarImageDataSource = self.tableView(
                self.tableView,
                avatarImageDataForItemAtIndexPath: indexPath)
            if (avatarImageDataSource != nil) {
                let avatarImage: UIImage? = avatarImageDataSource!.avatarImage
                if (avatarImage == nil) {
                    cell.avatarImageView.image = avatarImageDataSource!.avatarPlaceholderImage
                    cell.avatarImageView.highlightedImage = nil
                } else {
                    cell.avatarImageView.image = avatarImage
                    cell.avatarImageView.highlightedImage = avatarImageDataSource!.avatarHighlightedImage
                }
            }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "chats.to.messages") {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                    print("ContactPickerDelege!")
                    let user = XMPPChatManager.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
                    cpd.didSelectContact(user)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView,
        avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        // return GGModelData.sharedInstance.getAvatar(Demo.id_jobs)
        let user = XMPPChatManager.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        return GGModelData.sharedInstance.getAvatar(user.jidStr)
    }
    
    func onRosterContentChanged(controller: NSFetchedResultsController) {
        print("onRosterContentChanged")
        self.tableView.reloadData()
    }
}
