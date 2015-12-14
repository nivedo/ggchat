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
    
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      
        self.welcomeLabel.text = "gg chat"
        self.welcomeLabel.textColor = UIColor.darkGrayColor()
        self.welcomeLabel.font = UIFont.boldSystemFontOfSize(CGFloat(30))
        
        // Initialize username and password
        if let previousUsername = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.username) {
            self.usernameTextField.placeholder = previousUsername
        } else {
        }
        if let previousPassword = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.password) {
            self.passwordTextField.placeholder = previousPassword
        } else {
        }
        
        
        if let previousUsername = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.username) {
            self.usernameTextField.text = previousUsername
        }
        self.usernameTextField.placeholder = "Username"
        self.usernameTextField.autocorrectionType = UITextAutocorrectionType.No
        self.usernameTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.usernameTextField.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.usernameTextField.layer.borderWidth = 1
        self.usernameTextField.layer.cornerRadius = CGFloat(5.0)
        
        if let previousPassword = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.password) {
            self.passwordTextField.text = previousPassword
        }
        self.passwordTextField.placeholder = "Password"
        self.passwordTextField.secureTextEntry = true
        self.passwordTextField.autocorrectionType = UITextAutocorrectionType.No;
        self.passwordTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.passwordTextField.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.passwordTextField.layer.borderWidth = 1
        self.passwordTextField.layer.cornerRadius = CGFloat(5.0)
        
        // Initialize buttons
        self.loginButton.setTitle("Login", forState: .Normal);
        // loginButton.addTarget(self, action: "handleLoginButtonClick:", forControlEvents: .TouchUpInside);
        self.loginButton.backgroundColor = UIColor.clearColor();
        self.loginButton.layer.cornerRadius = 5
        self.loginButton.layer.borderWidth = 1
        self.loginButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.loginButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal);
    }

    @IBAction func loginAction(sender: AnyObject) {
        // self.usernameTextField.text = "admin"
        // self.passwordTextField.text = "asdf"
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
        
        print("Logging in with \(self.usernameTextField.text!):\(self.passwordTextField.text!)")
        
        XMPPManager.sharedInstance.connect(
            username: self.usernameTextField.text!,
            password: self.passwordTextField.text!,
            connectCompletionHandler: connectCallback,
            authenticateCompletionHandler: authenticateCallback)
    }
   
    func connectCallback(stream: XMPPStream, error: String?) {
        if (error != nil) {
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = error!
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }
    
    func authenticateCallback(stream: XMPPStream, error: String?) {
        if (error == nil) {
            /*
            // Save usernmae
            NSUserDefaults.standardUserDefaults().setValue(self.usernameTextField.text, forKey: GGKey.username)
            NSUserDefaults.standardUserDefaults().setValue(self.passwordTextField.text, forKey: GGKey.password)
            NSUserDefaults.standardUserDefaults().synchronize()
            */
            
            // Send notification
            let notification = NSNotification(name: "loginSuccessful", object: self)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            
            // TODO: Not sure if this the best place for this function
            // AppManager.sharedInstance.updateClusterList()
            
            // Dismiss login screen
            // self.dismissViewControllerAnimated(true, completion: nil)
            performSegueWithIdentifier("login.to.chats", sender: self)
        } else {
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = "Wrong password."
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }
    
    @IBAction func signupAction(sender: AnyObject) {
        self.performSegueWithIdentifier("login.to.signup",
            sender: sender)
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
