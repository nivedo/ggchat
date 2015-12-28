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
        
        XMPPRosterManager.sharedInstance.delegate = self
        /*
        XMPPManager.sharedInstance.connect(
            username: nil,
            password: nil,
            connectCompletionHandler: nil,
            authenticateCompletionHandler: nil)
        */
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultController.view.removeFromSuperview()
        
        XMPPRosterManager.sharedInstance.delegate = nil
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
    
    var dataList: NSArray {
        get {
            return self.inSearchMode ? self.filteredChatsList : XMPPChatManager.getChatsList()
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
        let user = self.dataList.objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
      
        var displayName = user.jidStr
        if let vcard = XMPPvCardManager.sharedInstance.getvCardForJID(user.jid) {
            displayName = vcard.nickname
        }
       
        if displayName != nil {
            cell.cellTopLabel.attributedText = NSAttributedString(string: displayName)
            cell.cellBottomLabel.attributedText = NSAttributedString(string: user.jidStr)
            cell.cellCornerLabel.attributedText = NSAttributedString(string: MessageTimestampFormatter.sharedInstance.timestampForDate(NSDate()))
            
            (cell.avatarImageView.image, cell.avatarImageView.highlightedImage) = XMPPManager.avatarImageForJID(user.jidStr)
        } else {
            cell.cellTopLabel.text = ""
            cell.cellBottomLabel.text = ""
            cell.cellCornerLabel.text = ""
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
        
        let user: XMPPUserCoreDataStorageObject = self.dataList.objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        self.searchResultController.searchBar.resignFirstResponder()
        self.searchResultController.active = false
        
        self.performSegueWithIdentifier("chats.to.messages", sender: user)
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
