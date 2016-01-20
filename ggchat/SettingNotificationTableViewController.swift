//
//  SettingNotificationTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 1/19/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import UIKit

class SettingNotificationTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Notifications"
       
        self.tableView.registerNib(SettingTableSwitchCell.nib(),
            forCellReuseIdentifier: SettingTableSwitchCell.cellReuseIdentifier())
        // self.tableView.registerNib(SettingTableHeaderCell.nib(),
        //    forCellReuseIdentifier: SettingTableHeaderCell.cellReuseIdentifier())
        
        self.tableView.tableFooterView = UIView()
        self.tableView.tableFooterView?.hidden = true
        self.tableView.backgroundColor = self.tableView.separatorColor
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return GGSettingData.sharedInstance.notifications.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GGSettingData.sharedInstance.notifications[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let notification = GGSettingData.sharedInstance.notifications[indexPath.section][indexPath.row]
       
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableSwitchCell.cellReuseIdentifier(), forIndexPath: indexPath) as! SettingTableSwitchCell
       
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.cellMainLabel.text = notification.displayName
        cell.toggleSwitch.addTarget(self, action: Selector("switchChanged:"), forControlEvents: UIControlEvents.ValueChanged)

        return cell
    }
    
    func switchChanged(sender: UISwitch) {
        // print("switchChanged \(sender.superview?.superview)")
        if let cell = sender.superview?.superview as? UITableViewCell {
            if let indexPath = self.tableView.indexPathForCell(cell) {
                let notification = GGSettingData.sharedInstance.notifications[indexPath.section][indexPath.row]
                if notification.id == "sound" {
                    UserAPI.sharedInstance.updateSound(sender.on, jsonCompletion: nil)
                }
            }
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
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableHeaderCell.cellReuseIdentifier()) as! SettingTableHeaderCell
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(44.0)
    }
}
