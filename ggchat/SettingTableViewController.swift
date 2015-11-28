//
//  SettingTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Settings"
        self.tableView.tableFooterView = UIView()
        self.tableView.tableFooterView?.hidden = true
        self.tableView.backgroundColor = self.tableView.separatorColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return GGSettingData.sharedInstance.menus.count + 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 2
        } else {
            return GGSettingData.sharedInstance.menus[section-1].count
        }
    }
   
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return CGFloat(0.0)
        } else {
            return CGFloat(32.0)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 0 && indexPath.row == 0) {
            return CGFloat(80.0)
        }
        return CGFloat(44.0)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Settings clicked \(indexPath)")
        if (indexPath.section == 0 && indexPath.row == 1) {
            self.selectAvatarImage()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableAvatarCell.cellReuseIdentifier(),
                    forIndexPath: indexPath) as! SettingTableAvatarCell
                cell.cellTopLabel.attributedText = NSAttributedString(string: XMPPManager.senderDisplayName)
                cell.cellTopLabel.font = UIFont.boldSystemFontOfSize(CGFloat(18.0))
                
                let status = XMPPManager.sharedInstance.isConnected() ? "online" : "offline"
                cell.cellBottomLabel.attributedText = NSAttributedString(string: status)
                
                (cell.avatarImageView.image, cell.avatarImageView.highlightedImage) = XMPPManager.avatarImageForJID(XMPPManager.senderId)
                
                let gesture = UITapGestureRecognizer(target: self, action: "selectAvatarImage")
                cell.avatarContainer.addGestureRecognizer(gesture)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableViewCell.cellReuseIdentifier(),
                    forIndexPath: indexPath) as! SettingTableViewCell
                cell.cellMainLabel.attributedText = NSAttributedString(string: "Set Profile Photo")
                cell.hideArrow()
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableViewCell.cellReuseIdentifier(),
                forIndexPath: indexPath) as! SettingTableViewCell

            // Configure the cell...
            let menu = GGSettingData.sharedInstance.menus[indexPath.section-1][indexPath.row]
            cell.cellMainLabel.attributedText = NSAttributedString(string: menu.displayName)
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableHeaderCell.cellReuseIdentifier()) as! SettingTableHeaderCell
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
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
                // GGModelData.sharedInstance.addPhotoMediaMessage()
        }
        let actionChoosePhoto = UIAlertAction(
            title: "Choose Photo",
            style: UIAlertActionStyle.Default) { action -> Void in
                // GGModelData.sharedInstance.addVideoMediaMessage()
        }
        alert.addAction(actionTakePhoto)
        alert.addAction(actionChoosePhoto)
        alert.addAction(actionCancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
