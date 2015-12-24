//
//  ProfileViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class ProfileViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    let photoPicker = UIImagePickerController()
    
    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var helpTextView: UITextView!
    
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        /*
        let back: UIBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("backPressed:"))
        self.navigationItem.leftBarButtonItem = back
        */
        self.navigationItem.title = "Setup Profile"
        
        self.displayNameTextField.placeholder = "Display Name"
        
        self.helpTextView.textColor = UIColor.lightGrayColor()
        self.helpTextView.text = ""
        self.helpTextView.editable = false
        self.helpTextView.userInteractionEnabled = false
        self.helpTextView.text = "Please enter a display name and upload a photo that will help your friends find you. Profile names and photos are visible to other users."
        
        self.submitButton.setTitle("Submit", forState: .Normal);
        self.submitButton.backgroundColor = UIColor.clearColor();
        self.submitButton.layer.cornerRadius = 5
        self.submitButton.layer.borderWidth = 1
        self.submitButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.submitButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal);
     
        let avatar = GGModelData.sharedInstance.getAvatar(UserAPI.sharedInstance.jid!, displayName: UserAPI.sharedInstance.username!)
        self.avatarImage.image = avatar.avatarImage
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("dismissKeyboard"))
        
        self.view.addGestureRecognizer(tap)
        
        let gesture = UITapGestureRecognizer(target: self, action: "selectAvatarImage")
        self.avatarContainer.addGestureRecognizer(gesture)
        
        // Initialize photo and camera delegates
        self.photoPicker.delegate = self
    }
    
    func dismissKeyboard() {
        self.displayNameTextField.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        self.formatTextField(self.displayNameTextField)
    }
    
    func formatTextField(textField: UITextField) {
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.lightGrayColor().CGColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
        
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.spellCheckingType = UITextSpellCheckingType.No
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitPressed(sender: AnyObject) {
        let displayName = self.displayNameTextField.text!
        if (displayName == "") {
            let alert = UIAlertView()
            alert.title = "Please enter display name!"
            alert.addButtonWithTitle("OK")
            alert.show()
            return
        }
        UserAPI.sharedInstance.updateNickname(displayName, jsonCompletion: nil)
        self.performSegueWithIdentifier("profile.to.home", sender: self)
    }

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
    
    //////////////////////////////////////////////////////////////////////////////////
    // UIImagePickerControllerDelegate
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
            let newSize: CGFloat = self.avatarContainer.frame.width // CGFloat(100.0)
            let resizedImage = chosenImage.gg_imageScaledToSize(CGSize(width: newSize, height: newSize), isOpaque: true)
           
            let jid = UserAPI.sharedInstance.jid!
            GGModelData.sharedInstance.updateAvatar(jid, image: resizedImage)
            let avatar = GGModelData.sharedInstance.getAvatar(jid)
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Uploading avatar."
            UserAPI.sharedInstance.updateAvatarImage(resizedImage, jsonCompletion: { (jsonBody: [String: AnyObject]?) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = jsonBody {
                        self.avatarImage.image = avatar.avatarImage
                    }
                    MBProgressHUD.hideHUDForView(self.view, animated: false)
                }
            })
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
