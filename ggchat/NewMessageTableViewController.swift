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
    XMPPRosterManagerDelegate {

    var searchResultController = UISearchController()
    var searchFetchController: NSFetchedResultsController?
    
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
        
        XMPPRosterManager.sharedInstance.delegate = self
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
            
            self.searchFetchController = XMPPRosterManager.sharedInstance.newFetchedResultsController(searchPredicate)
            self.searchFetchController?.delegate = self
            
            print("updateSearch, active: \(self.searchResultController.active)")
        }
        self.tableView.reloadData()
    }
   
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.reloadData()
    }
    
    var inSearchMode: Bool {
        get {
            return self.searchResultController.active
                && self.searchResultController.searchBar.text!.characters.count > 0
        }
    }
    
    func frc() -> NSFetchedResultsController? {
        return self.inSearchMode ? self.searchFetchController : XMPPRosterManager.sharedInstance.fetchedResultsController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.frc()!.sections!.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sections: NSArray = self.frc()!.sections!
        
        if (section < sections.count) {
            return sections[section].numberOfObjects
        }
        
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! ContactTableViewCell

        // Configure the cell...
       
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
        
        let user: XMPPUserCoreDataStorageObject = frc()!.objectAtIndexPath(indexPath) as! XMPPUserCoreDataStorageObject
        var displayName = user.jidStr
        if (user.nickname != nil && user.nickname != "") {
            displayName = user.nickname
        }
        cell.cellMainLabel.attributedText = NSAttributedString(string: displayName)
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("clicked \(indexPath)")
        self.searchResultController.searchBar.resignFirstResponder()
        self.searchResultController.active = false
        
        self.performSegueWithIdentifier("new_message.to.messages", sender: self)
    }
    
    func backButtonPressed(button: UIBarButtonItem) {
        print("back button pressed")
        self.navigationController?.popToRootViewControllerAnimated(true)
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "new_message.to.messages") {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let cpd = segue.destinationViewController as? ContactPickerDelegate {
                    print("ContactPickerDelege!")
                    cpd.didSelectContact(XMPPRosterManager.userFromRosterAtIndexPath(indexPath: indexPath))
                }
                if let mvc = segue.destinationViewController as? MessageViewController {
                    mvc.overrideNavBackButtonToRootViewController = true
                }
            }
        }
    }

    func tableView(tableView: UITableView,
        avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        // let id = GGModelData.sharedInstance.contacts[indexPath.row].id
        let user: XMPPUserCoreDataStorageObject = XMPPRosterManager.userFromRosterAtIndexPath(indexPath: indexPath)
        return GGModelData.sharedInstance.getAvatar(user.jidStr)
    }
    
    //////////////////////////////////////////////////////////////////////////
    // NSFetchedResultsControllerDelegate methods
    //////////////////////////////////////////////////////////////////////////
   
    func onRosterContentChanged(controller: NSFetchedResultsController) {
        print("onRosterContentChanged")
        self.tableView.reloadData()
    }
}
