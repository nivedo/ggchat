//
//  ProfileViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("dismissKeyboard"))
        
        self.view.addGestureRecognizer(tap)
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
}
