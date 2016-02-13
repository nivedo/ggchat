//
//  ContactTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD
import SwiftAddressBook

protocol ContactPickerDelegate{
    func didSelectContact(recipient: RosterUser)
}

class ContactTableViewController: UITableViewController,
    UISearchResultsUpdating,
    XMPPMessageManagerDelegate,
    UserDelegate {

    var searchResultController = UISearchController()
    var filteredBuddyList = [RosterUser]()
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
        let actionImportFromContacts = UIAlertAction(
            title: "Import from Contacts",
            style: UIAlertActionStyle.Default) { action -> Void in
            self.addContactFromAddressBook()
        }
        let actionImportFromFacebook = UIAlertAction(
            title: "Import from Facebook",
            style: UIAlertActionStyle.Default) { action -> Void in
            self.addContactFromFacebook()
        }
        alert.addAction(actionEnterUsername)
        alert.addAction(actionImportFromContacts)
        alert.addAction(actionImportFromFacebook)
        alert.addAction(actionCancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addContactFromFacebook() {
        if let fbAccess = FBSDKAccessToken.currentAccessToken() {
            self.addFriendFromFacebook()
        } else {
            FacebookManager.sharedInstance.loginManager.logInWithReadPermissions(FacebookManager.readPermissions,
                fromViewController: self,
                handler: { (result, error) -> Void in
                if error != nil {
                    FacebookManager.sharedInstance.loginManager.logOut()
                } else if (result.isCancelled) {
                    FacebookManager.sharedInstance.loginManager.logOut()
                } else {
                    self.addFriendFromFacebook()
                }
            })
        }
    }
    
    func addFriendFromFacebook() {
        dispatch_async(dispatch_get_main_queue()) {
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Importing Facebook friends"
        }
        FacebookManager.addFriendsData({ (jsonBody: [String: AnyObject]?, errorMsg: String?) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                MBProgressHUD.hideHUDForView(self.view, animated: false)
                if let json = jsonBody {
                    if let addedBuddiesCount = json["added_buddies_count"] as? Int {
                        if addedBuddiesCount > 0 {
                            UserAPI.sharedInstance.sync()
                        } else {
                            let alert = UIAlertView()
                            alert.title = "Alert"
                            alert.message = "No Facebook friends using GG Chat"
                            alert.addButtonWithTitle("OK")
                            alert.show()
                        }
                    }
                } else if let err = errorMsg {
                    let alert = UIAlertView()
                    alert.title = "Alert"
                    alert.message = err
                    alert.addButtonWithTitle("OK")
                    alert.show()
                }
            }
        })
    }
    
    func addContactFromAddressBook() {
        SwiftAddressBook.requestAccessWithCompletion({ (success, error) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    hud.labelText = "Importing address book..."
                }
                if let people = swiftAddressBook?.allPeople {
                    var persons = [[String: AnyObject]]()
                    for person in people {
                        var json = [String: AnyObject]()
                        json["firstName"] = person.firstName
                        json["lastName"] = person.lastName
                       
                        var identity = false
                        if let emails = person.emails?.map( {$0.value} ) {
                            json["emails"] = emails
                            identity = true
                        }
                        if let phoneNumbers = person.phoneNumbers?.map( {$0.value} ) {
                            json["phoneNumbers"] = phoneNumbers
                            identity = true
                        }
                        if identity {
                            persons.append(json)
                        }
                    }
                    print("Parsed \(persons.count) in contacts")
                    UserAPI.sharedInstance.addBuddiesFromAddressBook(persons, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                        print(jsonBody)
                        dispatch_async(dispatch_get_main_queue()) {
                            if let json = jsonBody {
                                if let addedBuddiesCount = json["added_buddies_count"] as? Int {
                                    if addedBuddiesCount > 0 {
                                        // self.tableView.reloadData()
                                        UserAPI.sharedInstance.sync()
                                    } else {
                                        let alert = UIAlertView()
                                            alert.title = "Alert"
                                            alert.message = "No contacts in address book using GG Chat"
                                            alert.addButtonWithTitle("OK")
                                            alert.show()
                                    }
                                    MBProgressHUD.hideHUDForView(self.view, animated: false)
                                    return
                                }
                            }
                            MBProgressHUD.hideHUDForView(self.view, animated: false)
                        }
                    })
                }
            } else {
                print("Access to address book denied.")
            }
        })
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
                        // print(username)
                        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                        hud.labelText = "Search for \(username)"
                        UserAPI.sharedInstance.addBuddy(username, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                            dispatch_async(dispatch_get_main_queue()) {
                                MBProgressHUD.hideHUDForView(self.view, animated: false)
                                if let json = jsonBody {
                                    print(json)
                                    if let errorMsg = json["error"] as? String {
                                        let alert = UIAlertView()
                                        alert.title = "Alert"
                                        alert.message = errorMsg
                                        alert.addButtonWithTitle("OK")
                                        alert.show()
                                    } else {
                                        UserAPI.sharedInstance.sync()
                                    }
                                }
                            }
                        })
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
        // self.tableView.reloadData()
       
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self,
            action: "handleRefresh:",
            forControlEvents: UIControlEvents.ValueChanged)
    }
    
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        // print("handleRefresh")
        UserAPI.sharedInstance.sync({ (success: Bool) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
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
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (self.inSearchMode) {
            let searchString = searchController.searchBar.text!.lowercaseString
            self.filteredBuddyList = self.buddyList.filter { user in
                return user.displayName.lowercaseString.containsString(searchString)
            }
        }
        // print("updateSearchResults: \(self.inSearchMode), count: \(self.dataList.count)")
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
                return self.filteredBuddyList
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
        return self.dataList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ContactTableViewCell

        let user = self.dataList[indexPath.row]
        
        let avatar = user.messageAvatarImage
        cell.avatarImageView.image = avatar.avatarImage
        // cell.avatarImageView.highlightedImage = avatar.avatarHighlightedImage
        cell.cellMainLabel.attributedText = NSAttributedString(string: user.displayName)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("clicked \(indexPath)")
        
        let user = self.dataList[indexPath.row]
        
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
                        let user = self.dataList[indexPath.row]
                        UserAPI.sharedInstance.deleteBuddy(user.jid, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                            if let json = jsonBody {
                                print(json)
                                dispatch_async(dispatch_get_main_queue()) {
                                    if let errorMsg = json["error"] as? String {
                                        let alert = UIAlertView()
                                        alert.title = "Alert"
                                        alert.message = errorMsg
                                        alert.addButtonWithTitle("OK")
                                        alert.show()
                                    } else {
                                        self.buddyList = UserAPI.sharedInstance.removeBuddy(user.jid)
                                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                                        UserAPI.sharedInstance.sync()
                                    }
                                }
                            }
                        })
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
            TabBarController.incrementChatsBadge(self.tabBarController, message: message)
        }
    }
    
    func receiveReadReceipt(from: String, readReceipt: ReadReceipt) {
        
    }
}
