//
//  LoginViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/25/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
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
        self.usernameTextField.keyboardType = UIKeyboardType.EmailAddress
        
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
        
        // Initialize facebook login
        let fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 230.0)
        fbLoginButton.readPermissions = FacebookManager.readPermissions
        fbLoginButton.delegate = self
        /*
        fbLoginButton.addTarget(self,
            action: Selector("fbLoginButtonClicked"),
            forControlEvents: UIControlEvents.TouchUpInside)
        */
        self.view.addSubview(fbLoginButton)
        
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
            print(error)
            let alert = UIAlertView()
            alert.title = "Unable to login to Facebook"
            alert.addButtonWithTitle("OK")
            alert.show()
            
            FacebookManager.sharedInstance.loginManager.logOut()
        }
        else if result.isCancelled {
            // Handle cancellations
            FacebookManager.sharedInstance.loginManager.logOut()
        }
        else {
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Logging in with Facebook"
            
            var allPermsGranted = true
            let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
            for permission in FacebookManager.readPermissions {
                if !grantedPermissions.contains(permission) {
                    allPermsGranted = false
                    break
                }
            }
            if allPermsGranted {
                FacebookManager.fetchUserData({ (facebookUser: FacebookUser?, errorMsg: String?) -> Void in
                    if let fbUser = facebookUser {
                        print(fbUser.description)
                        UserAPI.sharedInstance.loginWithFacebook(fbUser, completion: self.loginCompletion)
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    func dismissKeyboard() {
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    func loadUserDefaults() {
        // if let previousEmail = NSUserDefaults.standardUserDefaults().stringForKey(GGKey.email) {
        if let previousEmail = UserAPI.sharedInstance.emailFromUserDefaults {
            self.usernameTextField.text = previousEmail
        }
        if let previousPassword = UserAPI.sharedInstance.passwordFromUserDefaults {
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
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.labelText = "Logging in"
        
        UserAPI.sharedInstance.login(email,
            password: password,
            completion: self.loginCompletion)
    }
    
    func loginCompletion(success: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            if success {
                print("Connecting with \(UserAPI.sharedInstance.jid!):\(UserAPI.sharedInstance.jpassword!)")
                XMPPManager.sharedInstance.connectWithCompletion(
                    self.connectCallback,
                    authenticateCompletionHandler: self.authenticateCallback)
            } else {
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                let alert = UIAlertView()
                alert.title = "Login Failed"
                alert.message = "Incorrect username or password"
                alert.addButtonWithTitle("Retry")
                alert.show()
            }
        }
    }
   
    func connectCallback(stream: XMPPStream, error: String?) {
        if (error != nil) {
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = error!
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }
    
    func authenticateCallback(stream: XMPPStream, error: String?) {
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        if (error == nil) {
            // Send notification
            let notification = NSNotification(name: "loginSuccessful", object: self)
            NSNotificationCenter.defaultCenter().postNotification(notification)
           
            // Update friends list from graph if logged in using facebook
            if let _ = FBSDKAccessToken.currentAccessToken() {
                FacebookManager.fetchFriendsData({ (friendsArray: [[String: String]]?, errorMsg: String?) -> Void in
                    if let friends = friendsArray {
                        UserAPI.sharedInstance.addBuddiesFromFacebook(friends, completion: { (jsonBody: [String: AnyObject]?) -> Void in
                            print(jsonBody)
                        })
                    }
                })
            }
            
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
