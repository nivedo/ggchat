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
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.8))
        let image = UIImage(named: "zorbo")

        let screenSize = UIScreen.mainScreen().bounds
        let xTarget = screenSize.width * 0.8
        let scaleFactor = xTarget / image!.size.width
        let yTarget = scaleFactor * image!.size.height
        let newSize = CGSizeMake(xTarget, yTarget)
        
        self.imageView.image = image?.gg_imageScaledToSize(newSize, isOpaque: true)
        /*
        self.imageView.frame = CGRectMake(
            self.imageView.frame.origin.x,
            self.imageView.frame.origin.y,
            image!.size.width,
            image!.size.height)
        */
        
        self.imageContainer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(1))
        let imageLayer = self.imageContainer.layer
        imageLayer.masksToBounds = true
        imageLayer.cornerRadius = CGFloat(8.0)
        // imageLayer.borderColor = UIColor.blackColor().CGColor
        // imageLayer.borderWidth = CGFloat(3.0)
        
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
