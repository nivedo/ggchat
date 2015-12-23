//
//  MessageImageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/23/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var navBar: UINavigationBar!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let done: UIBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("donePressed:"))
        // self.navigationItem.leftBarButtonItem = done
        self.navBar.topItem!.leftBarButtonItem = done
        self.navBar.topItem!.title = ""
        self.navBar.backgroundColor = UIColor.whiteColor()
        // self.edgesForExtendedLayout = UIRectEdge.None
       
        self.updateImage()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("toggleNavBar:"))
        
        self.view.addGestureRecognizer(tap)
    }
    
    func donePressed(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleNavBar(gesture: UITapGestureRecognizer) {
        print("toggleNavBar")
        let barsHidden: Bool = self.navBar.hidden
        self.navBar.hidden = !barsHidden
    }
    
    func updateImage() {
        if let image = self.image {
            let screenSize = UIScreen.mainScreen().bounds.size
            self.imageView.image = image.gg_imageScaledToFitSize(screenSize, isOpaque: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // self.attributes = nil
        // self.imageAsset?.delegate = nil
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        // self.attributes = nil
        // self.imageAsset?.delegate = nil
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
