//
//  SignupViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/14/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    @IBOutlet weak var signupContainer: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
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
        self.navigationItem.title = "Sign up"
        
        self.usernameTextField.placeholder = "Username"
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
        self.passwordTextField.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        self.formatTextField(self.usernameTextField)
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
        if let username = self.usernameTextField.text, let password = self.passwordTextField.text {
            if (username == "" || password == "") {
                let alert = UIAlertView()
                alert.title = "Please enter both a username and password!"
                alert.addButtonWithTitle("OK")
                alert.show()
                return
            }
            
            self.usernameTextField.resignFirstResponder()
            self.passwordTextField.resignFirstResponder()
            
            self.registerNewUser(self.usernameTextField.text!,
                password: self.passwordTextField.text!)
        }
    }
    
    func registerNewUser(username: String, password: String) {
        UserAPI.sharedInstance.register(username,
            password: password, completion: { (success: Bool) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if success {
                    self.errorTextView.text = ""
                    
                    NSUserDefaults.standardUserDefaults().setValue(username, forKey: GGKey.username)
                    NSUserDefaults.standardUserDefaults().setValue(password, forKey: GGKey.password)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    self.errorTextView.text = "User name \(username) already exists."
                }
            }
        })
    }
    
    /*
    func registerNewUser(username: String, password: String) {
        let URL: NSURL = NSURL(string: "http://chat.blub.io:5280/rest/")!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL:URL)
        request.HTTPMethod = "POST"
        
        let bodyData = "register \(username) chat.blub.io \(password)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
       
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil && data != nil else { // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
           
            dispatch_async(dispatch_get_main_queue()) {
                if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                    print("responseString = \(responseString)")
                    if responseString.rangeOfString("success") != nil {
                        self.errorTextView.text = ""
                        
                        NSUserDefaults.standardUserDefaults().setValue(username, forKey: GGKey.username)
                        NSUserDefaults.standardUserDefaults().setValue("", forKey: GGKey.password)
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        self.errorTextView.text = responseString
                    }
                }
            }
        }
        task.resume()
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

}
