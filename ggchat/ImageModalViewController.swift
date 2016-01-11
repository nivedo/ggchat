//
//  ImageModalViewController.swift
//  ggchat
//
//  Created by Gary Chang on 12/2/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import MBProgressHUD
import Kingfisher

class ImageModalViewController: UIViewController {

    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
   
    var attributes: [String: AnyObject]?
    var imageAsset: GGWikiAsset?
    var callDismiss: Bool = false
    var onDismiss: ((sender: AnyObject?) -> Void)?
    
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
        if let attr = self.attributes, let id = attr[TappableText.tapAssetId] as? String {
            if let asset = GGWiki.sharedInstance.cardAssets[id] {
                /*
                image = asset.getUIImage()
                self.imageAsset = asset
                
                if image == nil {
                    // Image not downloaded yet
                    self.imageAsset?.delegate = self
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    hud.labelText = "Downloading card assets"
                } else {
                    MBProgressHUD.hideHUDForView(self.view, animated: false)
                }
                */
                
                let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                hud.mode = MBProgressHUDMode.AnnularDeterminate
                hud.labelText = "Downloading"
               
                // let placeholderImage = UIImage(named: "mtg_back")
                let placeholderImage = GGWikiCache.sharedInstance.retreiveImage(asset.placeholderURL)
                self.imageView.kf_setImageWithURL(asset.url,
                    placeholderImage: placeholderImage,
                    optionsInfo: nil,
                    progressBlock: { (receivedSize, totalSize) -> () in
                        // print("Download Progress: \(receivedSize)/\(totalSize)")
                        hud.progress = Float(receivedSize) / Float(totalSize)
                    },
                    completionHandler: { (image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> () in
                        // print("Downloaded")
                        if let img = image {
                            let screenSize = UIScreen.mainScreen().bounds
                            let xTarget = screenSize.width * 0.8
                            let scaleFactor = xTarget / img.size.width
                            let yTarget = scaleFactor * img.size.height
                            let newSize = CGSizeMake(xTarget, yTarget)
                            
                            self.imageView.image = img.gg_imageScaledToSize(newSize, isOpaque: false)
                            // self.imageView.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: newSize)
                        }
                        hud.hide(true)
                })
            } else {
                assert(false, "Cannot find asset id \(id)")
            }
        }
       
        /*
        if image != nil {
            let screenSize = UIScreen.mainScreen().bounds
            let xTarget = screenSize.width * 0.8
            let scaleFactor = xTarget / image!.size.width
            let yTarget = scaleFactor * image!.size.height
            let newSize = CGSizeMake(xTarget, yTarget)
            
            self.imageView.image = image?.gg_imageScaledToSize(newSize, isOpaque: false)
        }
        */
    }
    
    func reset() {
        self.callDismiss = false
        self.attributes = nil
        // self.imageAsset?.delegate = nil
        // self.imageView.image = nil
        // MBProgressHUD.hideHUDForView(self.view, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateModal()
    }
   
    /*
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
    }
    */
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gg_handleTapGesture(recognizer: UITapGestureRecognizer) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        if self.callDismiss {
            self.onDismiss?(sender: self)
        }
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
