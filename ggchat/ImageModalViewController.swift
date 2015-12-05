//
//  ImageModalViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD

class ImageModalViewController: UIViewController, ImageModalAssetDelegate {

    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
   
    var attributes: [String: AnyObject]?
    var imageAsset: ImageModalAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.8))
       
        self.imageContainer.backgroundColor = UIColor.clearColor()
        self.imageView.backgroundColor = UIColor.clearColor()
        
        let imageLayer = self.imageContainer.layer
        imageLayer.masksToBounds = true
        imageLayer.cornerRadius = CGFloat(8.0)
        
        self.updateModal()
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("gg_handleTapGesture:"))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateModal() {
        var image: UIImage?
        if let attr = self.attributes, let key = attr[TappableText.tapAssetKey] as? String {
            if let asset = TappableText.sharedInstance.imageModalAsset(key) {
                image = asset.getUIImage()
                self.imageAsset = asset
                if image == nil {
                    // Image not downloaded yet
                    self.imageAsset?.delegate = self
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    hud.labelText = "Downloading card assets"
                }
            } else {
                // TEMP: Placeholder for tokens without assets
                image = UIImage(named: "zorbo")
            }
        }
        
        if image != nil {
            let screenSize = UIScreen.mainScreen().bounds
            let xTarget = screenSize.width * 0.8
            let scaleFactor = xTarget / image!.size.width
            let yTarget = scaleFactor * image!.size.height
            let newSize = CGSizeMake(xTarget, yTarget)
            
            self.imageView.image = image?.gg_imageScaledToSize(newSize, isOpaque: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateModal()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.attributes = nil
        self.imageAsset?.delegate = nil
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        self.attributes = nil
        self.imageAsset?.delegate = nil
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
    
    func onDownloadError() {
        // Download error
    }
    
    func onDownloadSuccess(image: UIImage) {
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        updateModal()
    }
}
