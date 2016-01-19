//
//  ContactTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import Crashlytics

protocol ContactPickerDelegate{
    func didSelectContact(recipient: RosterUser)
}

class ContactTableViewController: UITableViewController,
    UISearchResultsUpdating,
    XMPPMessageManagerDelegate,
    UserDelegate {

    var searchResultController = UISearchController()
    var filteredRosterList = [RosterUser]()
    var buddyList = [RosterUser]()

    @IBAction func addContactAction(sender: AnyObject) {
        let alert: UIAlertController = UIAlertController(
            title: "Add people to chat with",
            // message: "Choose options",
            message: nil,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        let actionEnterUsername = UIAlertAction(
            title: "Enter Username",
            style: UIAlertActionStyle.Default) { action -> Void in
            self.addContactFromUsername()
        }
        let actionPickFromContacts = UIAlertAction(
            title: "Pick from Your Contacts",
            style: UIAlertActionStyle.Default) { action -> Void in
            self.addContactFromAddressBook()
        }
        /*
        let actionEnterPhoneNumber = UIAlertAction(
            title: "Enter Phone Number",
            style: UIAlertActionStyle.Default) { action -> Void in
        }
        */
        alert.addAction(actionEnterUsername)
        // alert.addAction(actionEnterPhoneNumber)
        alert.addAction(actionPickFromContacts)
        alert.addAction(actionCancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addContactFromAddressBook() {
        
    }
    
    func addContactFromUsername() {
        let alert: UIAlertController = UIAlertController(
            title: "Enter Username",
            message: nil,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
            textField.placeholder = NSLocalizedString("Username", comment: "Username")
        })
        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        let actionOk = UIAlertAction(
            title: "Ok",
            style: UIAlertActionStyle.Default,
            handler: { (action: UIAlertAction) -> Void in
                if let usernameTextField = alert.textFields?.first {
                    if let username = usernameTextField.text {
                        print(username)
                        UserAPI.sharedInstance.addBuddy(username, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                            if let json = jsonBody {
                                print(json)
                                if let errorMsg = json["error"] as? String {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        let alert = UIAlertView()
                                        alert.title = "Alert"
                                        alert.message = errorMsg
                                        alert.addButtonWithTitle("OK")
                                        alert.show()
                                    }
                                } else {
                                    UserAPI.sharedInstance.sync()
                                }
                            }
                        })
                        /*
                        UserAPI.sharedInstance.getUserinfo(username, jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                            if let json = jsonBody, let jidStr = json["jid"] as? String {
                                print("Adding \(jidStr)")
                                XMPPRosterManager.addUser(jidStr, nickname: "")
                            }
                        })
                        */
                    }
                }
            })
        
        alert.addAction(actionOk)
        alert.addAction(actionCancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(ContactTableViewCell.nib(),
            forCellReuseIdentifier: ContactTableViewCell.cellReuseIdentifier())
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Contacts"
        
        self.searchResultController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false // true
            controller.searchBar.sizeToFit()
            controller.searchBar.placeholder = "Search for contacts or usernames"
            controller.searchBar.searchBarStyle = UISearchBarStyle.Minimal
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        UserAPI.sharedInstance.delegate = self
        XMPPMessageManager.sharedInstance.delegate = self
        self.tableView.reloadData()
       
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self,
            action: "handleRefresh:",
            forControlEvents: UIControlEvents.ValueChanged)
    }
    
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        print("handleRefresh")
        UserAPI.sharedInstance.sync({ (success: Bool) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                refreshControl.endRefreshing()
            }
        })
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
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.buddyList = UserAPI.sharedInstance.buddyList
                self.tableView.reloadData()
            }
        }
    }
    
    func onChatsUpdate(success: Bool) {
        // Do nothing
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
      
        UserAPI.sharedInstance.delegate = self
        // UserAPI.sharedInstance.cacheRoster()
        
        self.buddyList = UserAPI.sharedInstance.buddyList
        TabBarController.updateChatsBar(self.tabBarController)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultController.view.removeFromSuperview()
        
        // XMPPRosterManager.sharedInstance.delegate = nil
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (self.inSearchMode) {
            let searchString = searchController.searchBar.text!.lowercaseString
            self.filteredRosterList = self.buddyList.filter { user in
                user.displayName.lowercaseString.containsString(searchString)
            }
            /*
            let searchPredicate = NSPredicate(format: "self.displayName CONTAINS[cd] %@",
                searchController.searchBar.text!)
           
            self.searchFetchController = XMPPRosterManager.sharedInstance.newFetchedResultsController(searchPredicate)
            self.searchFetchController?.delegate = self
            
            print("updateSearch, active: \(self.searchResultController.active)")
            */
        }
        self.tableView.reloadData()
    }
    
    var inSearchMode: Bool {
        get {
            return self.searchResultController.active
                && self.searchResultController.searchBar.text!.characters.count > 0
        }
    }
    
    var dataList: [RosterUser] {
        get {
            if self.inSearchMode {
                return self.filteredRosterList
            } else {
                return self.buddyList
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.buddyList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ContactTableViewCell

        let user = self.buddyList[indexPath.row]
        
        let avatar = user.messageAvatarImage
        cell.avatarImageView.image = avatar.avatarImage
        // cell.avatarImageView.highlightedImage = avatar.avatarHighlightedImage
        cell.cellMainLabel.attributedText = NSAttributedString(string: user.displayName)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("clicked \(indexPath)")
        
        let user = self.buddyList[indexPath.row]
        
        self.searchResultController.searchBar.resignFirstResponder()
        self.searchResultController.active = false
        
        self.performSegueWithIdentifier("contacts.to.messages", sender: user)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if !self.inSearchMode {
            if editingStyle == .Delete {
                // Delete the row from the data source
                let refreshAlert = UIAlertController(
                    title: "",
                    message: "Are you sure you want to delete this contact?",
                    preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                refreshAlert.addAction(UIAlertAction(title: "Delete contact",
                    style: .Destructive,
                    handler: { (action: UIAlertAction!) in
                        // XMPPChatManager.removeUserAtIndexPath(indexPath)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "contacts.to.messages") {
            let user = sender as! RosterUser
            if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                // print("ContactPickerDelege!")
                cpd.didSelectContact(user)
            }
        }
    }
    
    func receiveComposingMessage(from: String) {
        // Do nothing for chat view
    }
    
    func receiveMessage(from: String, message: Message) {
        dispatch_async(dispatch_get_main_queue()) {
            TabBarController.incrementChatsBadge(self.tabBarController)
        }
    }
    
    func receiveReadReceipt(from: String, readReceipt: ReadReceipt) {
        
    }
}
