//
//  SettingTableViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class SettingTableViewController:
    UITableViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    let photoPicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
       
        self.tableView.registerNib(SettingTableMenuCell.nib(),
            forCellReuseIdentifier: SettingTableMenuCell.cellReuseIdentifier())
        
        self.navigationItem.title = "Settings"
        self.tableView.tableFooterView = UIView()
        self.tableView.tableFooterView?.hidden = true
        self.tableView.backgroundColor = self.tableView.separatorColor
        
        // Initialize photo and camera delegates
        self.photoPicker.delegate = self
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    // UIImagePickerControllerDelegate
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
        let newSize: CGFloat = CGFloat(32.0)
        let resizedImage = chosenImage.gg_imageScaledToSize(CGSize(width: newSize, height: newSize), isOpaque: true)
        
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
    
    func imageWithImage(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    //////////////////////////////////////////////////////////////////////////////////
    // UINavigationControllerDelegate
    /*
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        // print("didShowViewController: \(navigationController.viewControllers.count)")
        if (navigationController.viewControllers.count == 3) {
            let edge: CGFloat = 10
            let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height
            let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
            let circleWidth: CGFloat = screenWidth - 2.0 * edge
            
            let plCropOverlay: UIView = viewController.view.subviews[1].subviews[0]
            
            plCropOverlay.hidden = true
            let position: CGFloat = 0.5 * (screenHeight - circleWidth)
            
            let circleLayer: CAShapeLayer = CAShapeLayer()
          
            let path2: UIBezierPath = UIBezierPath(ovalInRect: CGRectMake(edge, position, circleWidth, circleWidth))
            path2.usesEvenOddFillRule = true
            
            circleLayer.path = path2.CGPath
            
            circleLayer.fillColor = UIColor.clearColor().CGColor
            let path: UIBezierPath = UIBezierPath(roundedRect: CGRectMake(0, 0, screenWidth, screenHeight-72),cornerRadius:0)
            
            path.appendPath(path2)
            path.usesEvenOddFillRule = true
            
            let fillLayer: CAShapeLayer = CAShapeLayer()
            fillLayer.path = path.CGPath
            fillLayer.fillRule = kCAFillRuleEvenOdd
            fillLayer.fillColor = UIColor.blackColor().CGColor
            fillLayer.opacity = 0.7
            viewController.view.layer.addSublayer(fillLayer)
            
            let moveLabel: UILabel = UILabel(frame: CGRectMake(0, 10, screenWidth, 50))
            moveLabel.text = "Move and Scale"
            moveLabel.textAlignment = NSTextAlignment.Center
            moveLabel.textColor = UIColor.whiteColor()
            
            viewController.view.addSubview(moveLabel)
        }
    }
    */
   
    //////////////////////////////////////////////////////////////////////////////////
    
    override func viewWillAppear(animated: Bool) {
        // This call is necessary because popViewControllerAnimated will not
        // call viewDidLoad() or refresh the tableView after the pop
        
        self.tableView.reloadData()
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
            return 3
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
        if (indexPath.section == 0) {
            if (indexPath.row == 1) {
                self.selectAvatarImage()
            } else if (indexPath.row == 2) {
                self.performSegueWithIdentifier("settings.to.settings_textfield", sender: "displayName")
            }
        } else {
            let menu = GGSettingData.sharedInstance.menus[indexPath.section-1][indexPath.row]
            if (menu.segueName != "") {
                self.performSegueWithIdentifier(menu.segueName, sender: menu.id)
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableAvatarCell.cellReuseIdentifier(),
                    forIndexPath: indexPath) as! SettingTableAvatarCell
                cell.cellTopLabel.attributedText = NSAttributedString(string: UserAPI.sharedInstance.displayName)
                cell.cellTopLabel.font = UIFont.boldSystemFontOfSize(CGFloat(18.0))
                
                let status = XMPPManager.sharedInstance.isConnected() ? "online" : "offline"
                cell.cellBottomLabel.attributedText = NSAttributedString(string: status)
               
                let avatar = UserAPI.sharedInstance.avatar
                cell.avatarImageView.image = avatar.avatarImage
                cell.avatarImageView.highlightedImage = avatar.avatarHighlightedImage
                // XMPPManager.avatarImageForJID(XMPPManager.sharedInstance.jid)
                
                let gesture = UITapGestureRecognizer(target: self, action: "selectAvatarImage")
                cell.avatarContainer.addGestureRecognizer(gesture)
                
                return cell
            } else if (indexPath.row == 1) {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableMenuCell.cellReuseIdentifier(),
                    forIndexPath: indexPath) as! SettingTableMenuCell
                cell.cellMainLabel.attributedText = NSAttributedString(string: "Set Profile Photo")
                cell.hideArrow()
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableMenuCell.cellReuseIdentifier(),
                    forIndexPath: indexPath) as! SettingTableMenuCell
                cell.cellMainLabel.attributedText = NSAttributedString(string: "Set Display Name")
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingTableMenuCell.cellReuseIdentifier(),
                forIndexPath: indexPath) as! SettingTableMenuCell

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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "settings.to.settings_textfield") {
            if let stf = segue.destinationViewController as? SettingTextFieldTableViewController {
                if let id = sender as? String {
                    if id == "username" {
                        stf.beforeSegue("Username",
                            completionHandler: { (textValue: String) -> Void in
                                // XMPPvCardManager.sharedInstance.updateDisplayName(textValue)
                        })
                    } else if id == "displayName" {
                        stf.beforeSegue("Display Name",
                            completionHandler: { (textValue: String) -> Void in
                                UserAPI.sharedInstance.updateNickname(textValue, jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                                    if let _ = jsonBody {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.tableView.reloadData()
                                        }
                                    }
                                })
                        })
                    }
                }
            }
        } else if (segue.identifier == "settings.to.login") {
            XMPPManager.stop()
            UserAPI.sharedInstance.authToken = nil
            XMPPManager.start()
        }
    }

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
}
