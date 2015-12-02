//
//  ImageModalViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class ImageModalViewController: UIViewController {

    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        // self.view.opaque = false
        // self.view.alpha = CGFloat(0.6)
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.7))
        let image = UIImage(named: "zorbo")
        self.imageView.image = image
        self.imageView.frame = CGRectMake(
            self.imageView.frame.origin.x,
            self.imageView.frame.origin.y,
            image!.size.width,
            image!.size.height)
        
        self.imageContainer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(1))
        // self.imageView.layer.shouldRasterize = true
        // No setting rasterizationScale, will cause blurry images on retina.
        // self.imageView.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("gg_handleTapGesture:"))
        self.view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gg_handleTapGesture(recognizer: UITapGestureRecognizer) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
