//
//  SettingUsernameTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/28/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SettingUsernameTableViewController: UITableViewController, UITextFieldDelegate {

    var username: String?
    var textField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
       
        self.tableView.registerNib(SettingTableTextViewCell.nib(),
            forCellReuseIdentifier: SettingTableTextViewCell.cellReuseIdentifier())
        self.tableView.registerNib(SettingTableBorderCell.nib(),
            forCellReuseIdentifier: SettingTableBorderCell.cellReuseIdentifier())
        
        self.navigationItem.title = "Username"
        
        let rightBarButton: UIBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedDonePressed:"))
        self.navigationItem.rightBarButtonItem = rightBarButton
        let leftBarButton: UIBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("receivedCancelPressed:"))
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        self.tableView.tableFooterView = UIView()
        self.tableView.tableFooterView?.hidden = true
        self.tableView.backgroundColor = self.tableView.separatorColor
    }
    
    func receivedDonePressed(sender: AnyObject?) {
        if let textField = self.textField {
            self.username = textField.text
            textField.resignFirstResponder()
        }
        if let username = self.username {
            print("Update username with: \(username)")
            XMPPvCardManager.sharedInstance.updateDisplayName("Gary", familyName: "Chang")
        } else {
            print("No username specified.")
        }
    }
    
    func receivedCancelPressed(sender: AnyObject?) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    func textFieldDidEndEditing(textField: UITextField) {
        // print("textFieldEndEditing")
        self.username = textField.text
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableTextViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! SettingTableTextViewCell

        // Configure the cell...
        cell.cellLabel.attributedText = NSAttributedString(string: "Username")
        cell.cellTextField.delegate = self
        self.textField = cell.cellTextField

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
 
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableBorderCell.cellReuseIdentifier()) as! SettingTableBorderCell
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
}
