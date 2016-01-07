//
//  MessageImageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/23/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageImageViewController: UIViewController {

    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var navBar: UINavigationBar!
    var image_: UIImage?
    var image: UIImage? {
        set {
            if newValue != nil {
                let screenSize = UIScreen.mainScreen().bounds.size
                self.image_ = (newValue!.copy() as? UIImage)?.gg_imageScaledToFitSize(screenSize, isOpaque: true)
                print("set image: \(self.image_!.size)")
            } else {
                self.image_ = nil
            }
        }
        get {
            return self.image_
        }
    }
    
    override func viewDidLoad() {
        print("ImageVC::viewDidLoad()")
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
       
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("toggleNavBar:"))
        
        self.view.addGestureRecognizer(tap)
    }
   
    /*
    override func viewDidLayoutSubviews() {
        print("viewDidLayoutSubviews()")
        super.viewDidLayoutSubviews()
        self.updateImage()
    }
    */
    
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
            let y = 0.5 * (screenSize.height - image.size.height)
            self.imageView.frame = CGRectMake(0.0, y,
                image.size.width, image.size.height)
            self.imageView.image = image
            
            print("set frame \(self.imageView.frame)")
            print("container \(self.imageContainer.frame)")
        }
        /*
        if let image = self.image {
            // let screenSize = UIScreen.mainScreen().bounds.size
            // let newImage = image.gg_imageScaledToFitSize(screenSize, isOpaque: true)
            // print(newSize)
            // self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, newSize.width, newSize.height)
            self.imageView.image = image
            // self.imageView.center = self.imageView.superview!.center
        }
        */
    }
    
    func reset() {
        self.image = nil
        self.imageView.image = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        print("ImageVC::viewWillAppear()")
        super.viewWillAppear(animated)
        self.updateImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // self.attributes = nil
        // self.imageAsset?.delegate = nil
        self.reset()
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        // self.attributes = nil
        // self.imageAsset?.delegate = nil
        self.reset()
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
