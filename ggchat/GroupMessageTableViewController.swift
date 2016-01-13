//
//  GroupMessageTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 1/13/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class GroupMessageTableViewController:
    UITableViewController,
    UISearchResultsUpdating,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UserDelegate {
    
    var searchResultController = UISearchController()
    var filteredBuddyList = [RosterUser]()
    var buddyList = [RosterUser]()
    var selectedBuddySet = Set<RosterUser>()
    let photoPicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(ContactTableViewCell.nib(),
            forCellReuseIdentifier: ContactTableViewCell.cellReuseIdentifier())
        self.tableView.registerNib(ContactSelectTableViewCell.nib(),
            forCellReuseIdentifier: ContactSelectTableViewCell.cellReuseIdentifier())
        self.tableView.registerNib(GroupProfileTableViewCell.nib(),
            forCellReuseIdentifier: GroupProfileTableViewCell.cellReuseIdentifier())
        
        self.navigationItem.title = "New Group"
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
      
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
        
        let createButton: UIBarButtonItem = UIBarButtonItem(
            title: "Create",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedCreatePressed:"))
        self.navigationItem.rightBarButtonItem = createButton
        
        let cancelButton: UIBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedCancelPressed:"))
        self.navigationItem.leftBarButtonItem = cancelButton
       
        self.photoPicker.delegate = self
        UserAPI.sharedInstance.delegate = self
        self.buddyList = UserAPI.sharedInstance.buddyList
        self.tableView.reloadData()
    }
   
    var avatarSize: CGSize {
        get {
            let newSize: CGFloat = CGFloat(40.0)
            return CGSize(width: newSize, height: newSize)
        }
    }
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            
            let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
            let resizedImage = chosenImage.gg_imageScaledToSize(self.avatarSize, isOpaque: false)
            
            // let jid = UserAPI.sharedInstance.jid!
            // GGModelData.sharedInstance.updateAvatar(jid, image: resizedImage)
            
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Uploading avatar."
            UserAPI.sharedInstance.updateAvatarImage(resizedImage, jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let json = jsonBody {
                        print(json)
                        self.tableView.reloadData()
                    }
                    MBProgressHUD.hideHUDForView(self.view, animated: false)
                }
            })
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func receivedCancelPressed(button: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func receivedCreatePressed(sender: UIButton) {
        if self.selectedBuddySet.count < 3 {
            let alert = UIAlertView()
            alert.title = "Please Add More People"
            alert.message = "Groups must be at least 3 people"
            alert.addButtonWithTitle("OK")
            alert.show()
        } else {
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UserAPI.sharedInstance.delegate = self
        self.buddyList = UserAPI.sharedInstance.buddyList
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
                return self.filteredBuddyList
            } else {
                return self.buddyList
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    func selectAvatarImage() {
        let alert: UIAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil)
        let actionTakePhoto = UIAlertAction(
            title: "Take Photo",
            style: UIAlertActionStyle.Default) { action -> Void in
                self.photoPicker.allowsEditing = true
                self.photoPicker.sourceType = .Camera
                self.presentViewController(self.photoPicker, animated: true, completion: nil)
        }
        let actionChoosePhoto = UIAlertAction(
            title: "Choose Photo",
            style: UIAlertActionStyle.Default) { action -> Void in
                self.photoPicker.allowsEditing = true
                self.photoPicker.sourceType = .PhotoLibrary
                self.presentViewController(self.photoPicker, animated: true, completion: nil)
        }
        alert.addAction(actionTakePhoto)
        alert.addAction(actionChoosePhoto)
        alert.addAction(actionCancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 1 {
            return self.dataList.count
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(ContactTableViewCell.cellReuseIdentifier(),
                forIndexPath: indexPath) as! ContactTableViewCell

            // Configure the cell...
            let user = self.buddyList[indexPath.row]
            
            let avatar = user.messageAvatarImage
            cell.avatarImageView.image = avatar.avatarImage
            cell.cellMainLabel.attributedText = NSAttributedString(string: user.displayName)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(GroupProfileTableViewCell.cellReuseIdentifier(),
                forIndexPath: indexPath) as! GroupProfileTableViewCell
            
            let avatar = UserAPI.avatarFromInitials("G P")
            cell.avatarImageView.image = avatar.avatarImage?.gg_imageScaledToFitSize(self.avatarSize, isOpaque: false)
            
            let gesture = UITapGestureRecognizer(target: self, action: "selectAvatarImage")
            cell.avatarContainer.addGestureRecognizer(gesture)
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            self.searchResultController.searchBar.resignFirstResponder()
            self.searchResultController.active = false
            
            let user = self.buddyList[indexPath.row]
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! ContactTableViewCell
            if self.selectedBuddySet.contains(user) {
                cell.accessoryType = UITableViewCellAccessoryType.None
                self.selectedBuddySet.remove(user)
                self.tableView.reloadData()
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                self.selectedBuddySet.insert(user)
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return CGFloat(50.0)
        } else {
            return CGFloat(0.0)
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(ContactSelectTableViewCell.cellReuseIdentifier()) as! ContactSelectTableViewCell
            
            var selectedDisplayNames = [String]()
            for user in self.selectedBuddySet {
                selectedDisplayNames.append(user.displayName)
            }
            print(selectedDisplayNames.joinWithSeparator(", "))
            cell.textView.text = "To: \(selectedDisplayNames.joinWithSeparator(", "))"
            
            return cell
        } else {
            return nil
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
                self.buddyList = UserAPI.sharedInstance.buddyList
                self.tableView.reloadData()
            }
        }
    }
    
    func onChatsUpdate(success: Bool) {
        // Do nothing
    }
}
