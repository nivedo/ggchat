//
//  LoginViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let previousUsername = NSUserDefaults.standardUserDefaults().stringForKey("username") {
            self.usernameTextField.placeholder = previousUsername
        } else {
            self.usernameTextField.placeholder = "Username";
        }
        
        self.usernameTextField.autocorrectionType = UITextAutocorrectionType.No;
        self.usernameTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        
        self.passwordTextField.placeholder = "Password";
        self.passwordTextField.autocorrectionType = UITextAutocorrectionType.No;
        self.passwordTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        
        // Initialize buttons
        self.loginButton.setTitle("Login", forState: .Normal);
        // loginButton.addTarget(self, action: "handleLoginButtonClick:", forControlEvents: .TouchUpInside);
        self.loginButton.backgroundColor = UIColor.clearColor();
        self.loginButton.layer.cornerRadius = 5
        self.loginButton.layer.borderWidth = 1
        // loginButton.layer.borderColor = AppStyle.menuTextColor.CGColor
        // loginButton.setTitleColor(AppStyle.menuTextColor, forState: .Normal);
    }

    @IBAction func loginAction(sender: AnyObject) {
        self.usernameTextField.text = "admin"
        self.passwordTextField.text = "123"
        if (self.usernameTextField.text == "" || self.passwordTextField.text == "") {
            let alert = UIAlertView()
            alert.title = "Please enter both a username and password!"
            alert.addButtonWithTitle("OK")
            alert.show()
            return
        }
        
        // 2.
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        print("Logging in with \(self.usernameTextField.text):\(self.passwordTextField.text)")
        /*
        AppManager.sharedInstance.login(usernameTextField.text!,
            password: passwordTextField.text!,
            callback: loginCallback)
        */
    }
   
    func loginCallback(success: Bool, status: Int?) {
        if success {
            // Save usernmae
            NSUserDefaults.standardUserDefaults().setValue(self.usernameTextField.text, forKey: "username")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // Send notification
            let notification = NSNotification(name: "loginSuccessful", object: self)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            
            // TODO: Not sure if this the best place for this function
            // AppManager.sharedInstance.updateClusterList()
            
            // Dismiss login screen
            // self.dismissViewControllerAnimated(true, completion: nil)
            performSegueWithIdentifier("showChatViewAfterLogin", sender: self)
        } else {
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = "Wrong username or password."
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
