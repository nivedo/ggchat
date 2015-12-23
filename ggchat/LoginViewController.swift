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
        self.loadUserDefaults()
        
        self.usernameTextField.placeholder = "Email"
        self.usernameTextField.autocorrectionType = UITextAutocorrectionType.No
        self.usernameTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.usernameTextField.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.usernameTextField.layer.borderWidth = 1
        self.usernameTextField.layer.cornerRadius = CGFloat(5.0)
        
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
        self.loginButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("dismissKeyboard"))
        
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    func loadUserDefaults() {
        if let previousEmail = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.email) {
            self.usernameTextField.text = previousEmail
        }
        if let previousPassword = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.password) {
            self.passwordTextField.text = previousPassword
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.loadUserDefaults()
    }

    @IBAction func loginAction(sender: AnyObject) {
        let email = self.usernameTextField.text!
        let password = self.passwordTextField.text!
        if (email == "" || password == "") {
            let alert = UIAlertView()
            alert.title = "Please enter both an email and password!"
            alert.addButtonWithTitle("OK")
            alert.show()
            return
        }
        
        // 2.
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        print("Logging in with \(email):\(password)")
        UserAPI.sharedInstance.login(email,
            password: password,
            completion: { (success: Bool) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    NSUserDefaults.standardUserDefaults().setValue(email, forKey: GGKey.email)
                    NSUserDefaults.standardUserDefaults().setValue(password, forKey: GGKey.password)
                    NSUserDefaults.standardUserDefaults().synchronize()
    
                    print("Connecting with \(UserAPI.sharedInstance.jid!):\(UserAPI.sharedInstance.jpassword!)")
                    XMPPManager.sharedInstance.connectWithJID(
                        jid: UserAPI.sharedInstance.jid!,
                        password: UserAPI.sharedInstance.jpassword!,
                        connectCompletionHandler: self.connectCallback,
                        authenticateCompletionHandler: self.authenticateCallback)
                } else {
                    let alert = UIAlertView()
                    alert.title = "Login Failed"
                    alert.message = "Incorrect username or password"
                    alert.addButtonWithTitle("Retry")
                    alert.show()
                }
            }
        })
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
