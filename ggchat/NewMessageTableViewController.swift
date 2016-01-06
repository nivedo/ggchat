//
//  NewMessageTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class NewMessageTableViewController:
    UITableViewController,
    UISearchResultsUpdating,
    NSFetchedResultsControllerDelegate,
    UserDelegate {

    var searchResultController = UISearchController()
    var filteredRosterList = [RosterUser]()
    var rosterList = [RosterUser]()
    
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
        
        self.navigationItem.title = "New Message"
        
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
        self.rosterList = UserAPI.sharedInstance.rosterList
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       
        UserAPI.sharedInstance.delegate = self
        self.rosterList = UserAPI.sharedInstance.rosterList
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultController.view.removeFromSuperview()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (self.inSearchMode) {
            let searchString = searchController.searchBar.text!.lowercaseString
            self.filteredRosterList = self.rosterList.filter { user in
                user.displayName.lowercaseString.containsString(searchString)
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
    
    var dataList: [RosterUser] {
        get {
            if self.inSearchMode {
                return self.filteredRosterList
            } else {
                return self.rosterList
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
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ContactTableViewCell

        // Configure the cell...
        let user = self.rosterList[indexPath.row]
        
        let avatar = user.messageAvatarImage
        cell.avatarImageView.image = avatar.avatarImage
        cell.cellMainLabel.attributedText = NSAttributedString(string: user.displayName)
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("clicked \(indexPath)")
        
        let user = self.rosterList[indexPath.row]
        
        self.searchResultController.searchBar.resignFirstResponder()
        self.searchResultController.active = false
        
        self.performSegueWithIdentifier("new_message.to.messages", sender: user)
    }
    
    func backButtonPressed(button: UIBarButtonItem) {
        print("back button pressed")
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "new_message.to.messages") {
            let user = sender as! RosterUser
            if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                print("ContactPickerDelege!")
                cpd.didSelectContact(user)
            }
            if let mvc = segue.destinationViewController as? MessageViewController {
                mvc.overrideNavBackButtonToRootViewController = true
            }
        }
    }
    
    // MARK: - UserDelegate
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
                self.rosterList = UserAPI.sharedInstance.rosterList
                self.tableView.reloadData()
            }
        }
    }
    
    func onChatsUpdate(success: Bool) {
        // Do nothing
    }
}
