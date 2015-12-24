//
//  SignupViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/14/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class SignupViewController: UIViewController {

    @IBOutlet weak var signupContainer: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var errorTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let back: UIBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("backPressed:"))
        self.navigationItem.leftBarButtonItem = back
        self.navigationItem.title = "Sign Up"
        
        self.usernameTextField.placeholder = "Username"
        self.emailTextField.placeholder = "Email"
        self.passwordTextField.placeholder = "Password"
        self.passwordTextField.secureTextEntry = true
        
        self.errorTextView.textColor = UIColor.redColor()
        self.errorTextView.text = ""
        self.errorTextView.editable = false
        self.errorTextView.userInteractionEnabled = false
        
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
        self.usernameTextField.resignFirstResponder()
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        self.formatTextField(self.usernameTextField)
        self.formatTextField(self.emailTextField)
        self.formatTextField(self.passwordTextField)
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
    
    func backPressed(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    @IBAction func submitPressed(sender: AnyObject) {
        if let username = self.usernameTextField.text, let email = self.emailTextField.text, let password = self.passwordTextField.text {
            if (username == "" || password == "" || email == "") {
                let alert = UIAlertView()
                alert.title = "Please enter username, email, and password!"
                alert.addButtonWithTitle("OK")
                alert.show()
                return
            }
            
            self.usernameTextField.resignFirstResponder()
            self.emailTextField.resignFirstResponder()
            self.passwordTextField.resignFirstResponder()
            
            self.registerNewUser(self.usernameTextField.text!,
                email: self.emailTextField.text!,
                password: self.passwordTextField.text!)
        }
    }
    
    func registerNewUser(username: String, email: String, password: String) {
        UserAPI.sharedInstance.register(username,
            email: email,
            password: password,
            completion: { (success: Bool) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    hud.labelText = "Success! Logging in."
                    self.errorTextView.text = ""
                    
                    NSUserDefaults.standardUserDefaults().setValue(email, forKey: GGKey.email)
                    NSUserDefaults.standardUserDefaults().setValue(password, forKey: GGKey.password)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    // self.dismissViewControllerAnimated(true, completion: nil)
                    // self.performSegueWithIdentifier("signup.to.profile", sender: self)
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
                } else {
                    MBProgressHUD.hideHUDForView(self.view, animated: false)
                    self.errorTextView.text = "User name \(username) already exists."
                }
            }
        })
    }

    func connectCallback(stream: XMPPStream, error: String?) {
        if (error != nil) {
            MBProgressHUD.hideHUDForView(self.view, animated: false)
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = error!
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }

    func authenticateCallback(stream: XMPPStream, error: String?) {
        MBProgressHUD.hideHUDForView(self.view, animated: false)
        if (error == nil) {
            self.performSegueWithIdentifier("signup.to.profile", sender: self)
        } else {
            let alert = UIAlertView()
            alert.title = "Login Failed"
            alert.message = "Wrong password."
            alert.addButtonWithTitle("Retry")
            alert.show()
        }
    }
}
