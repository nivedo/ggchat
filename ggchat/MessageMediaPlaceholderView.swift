//
//  MessageMediaPlaceholderView.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageMediaPlaceholderView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    var activityIndicatorView: UIActivityIndicatorView?
    var imageView: UIImageView?
    
    class func viewWithActivityIndicator() -> MessageMediaPlaceholderView {
        let lightGrayColor: UIColor = UIColor.gg_messageBubbleLightGrayColor()
        let spinner: UIActivityIndicatorView = UIActivityIndicatorView (activityIndicatorStyle:UIActivityIndicatorViewStyle.White)
        spinner.color = lightGrayColor.gg_colorByDarkeningColorWithValue(0.4)
        
        let view: MessageMediaPlaceholderView = MessageMediaPlaceholderView(
            frame: CGRectMake(0.0, 0.0, 200.0, 120.0),
            backgroundColor: lightGrayColor,
            activityIndicatorView: spinner)
        return view
    }

    class func viewWithAttachmentIcon() -> MessageMediaPlaceholderView {
        let lightGrayColor: UIColor = UIColor.gg_messageBubbleLightGrayColor()
        let paperclip: UIImage = UIImage.gg_defaultAccessoryImage().gg_imageMaskedWithColor(lightGrayColor.gg_colorByDarkeningColorWithValue(0.4))
        let imageView: UIImageView = UIImageView(image: paperclip)
        
        let view: MessageMediaPlaceholderView = MessageMediaPlaceholderView(
            frame: CGRectMake(0.0, 0.0, 200.0, 120.0),
            backgroundColor: lightGrayColor,
            imageView: imageView)
        return view
    }

    convenience init(frame: CGRect,
        backgroundColor: UIColor,
        activityIndicatorView: UIActivityIndicatorView) {
        
        self.init(frame:frame, backgroundColor:backgroundColor)
        self.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        self.activityIndicatorView!.center = self.center
        self.activityIndicatorView!.startAnimating()
        self.imageView = nil
    }

    convenience init(frame: CGRect,
        backgroundColor: UIColor,
        imageView: UIImageView) {
        
        self.init(frame:frame, backgroundColor:backgroundColor)
        self.addSubview(imageView)
        self.imageView = imageView
        self.imageView!.center = self.center
        self.activityIndicatorView = nil
    }

    init(frame: CGRect,
        backgroundColor: UIColor) {
        
        super.init(frame:frame)
        self.backgroundColor = backgroundColor
        self.userInteractionEnabled = false
        self.clipsToBounds = true
        self.contentMode = UIViewContentMode.ScaleAspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // pragma mark - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (self.activityIndicatorView != nil) {
            self.activityIndicatorView!.center = self.center
        }
        else if (self.imageView != nil) {
            self.imageView!.center = self.center
        }
    }
}
