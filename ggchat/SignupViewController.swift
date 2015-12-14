//
//  SignupViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/14/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let back: UIBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("backPressed:"))
        self.navigationItem.leftBarButtonItem = back
        self.navigationItem.title = "Signup with GGChat"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backPressed(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
