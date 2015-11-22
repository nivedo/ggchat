//
//  RoomTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/20/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class RoomTableViewController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = true
        
        self.tableView.registerNib(
            RoomTableViewCell.nib(),
            forCellReuseIdentifier: RoomTableViewCell.cellReuseIdentifier())
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let appearance = UITabBarItem.appearance()
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(20.0)]
        appearance.setTitleTextAttributes(attributes, forState: .Normal)
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
        print("numberOfRowsInSection")
        return 2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("cellForRowAtIndexPath: \(indexPath)")
        
        let cell = tableView.dequeueReusableCellWithIdentifier(
            RoomTableViewCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! RoomTableViewCell
        
        // Configure the cell
        let room = self.tabeView(self.tableView, roomAtIndexPath: indexPath)
        
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
        
        cell.cellTopLabel.attributedText = self.tableView(self.tableView, attributedTextForCellTopLabelAtIndexPath: indexPath)
        cell.cellBottomLabel.attributedText = self.tableView(self.tableView, attributedTextForCellBottomLabelAtIndexPath: indexPath)
        cell.cellCornerLabel.attributedText = self.tableView(self.tableView, attributedTextForCellCornerLabelAtIndexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        print("willSelectRowAtIndexPath")
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndexPath")
        self.performSegueWithIdentifier("showMessageView", sender: indexPath)
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
    
    ////////////////////////////////////////////////////////////////////////////////
    // Data Source
    ////////////////////////////////////////////////////////////////////////////////
    
    func tabeView(tableView: UITableView,
        roomAtIndexPath indexPath: NSIndexPath) -> Room {
            return Room(roomId: "test_room")
    }
    
    func tableView(tableView: UITableView,
        avatarImageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageAvatarImage? {
        return GGModelData.sharedInstance.avatars[Demo.id_jobs]
    }
    
    func tableView(tableView: UITableView,
        attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "Gary Chang")
    }

    func tableView(tableView: UITableView,
        attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "This is the last message.")
    }

    func tableView(tableView: UITableView,
        attributedTextForCellCornerLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "April 25")
    }
}
