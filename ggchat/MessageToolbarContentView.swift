//
//  MessageToolbarContentView.swift
//  ggchat
//
//  Created by Gary Chang on 11/17/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageToolbarContentView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    static let kMessagesToolbarContentViewHorizontalSpacingDefault = 8.0
    @IBOutlet weak var leftBarButtonContainerView: UIView!
    @IBOutlet weak var rightBarButtonContainerView: UIView!
    

/*
@property (weak, nonatomic) IBOutlet MessagesComposerTextView *textView;

@property (weak, nonatomic) IBOutlet UIView *leftBarButtonContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftBarButtonContainerViewWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *rightBarButtonContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightBarButtonContainerViewWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftHorizontalSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightHorizontalSpacingConstraint;

@end
*/


    // pragma mark - Class methods
    class func nib() -> UINib {
        return UINib(nibName: NSStringFromClass(self),
            bundle: NSBundle(forClass: self))
    }

    // pragma mark - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()

        self.translatesAutoresizingMaskIntoConstraints = false
        
        /*
        self.leftHorizontalSpacingConstraint.constant = kMessagesToolbarContentViewHorizontalSpacingDefault
        self.rightHorizontalSpacingConstraint.constant = kMessagesToolbarContentViewHorizontalSpacingDefault
        */
        self.backgroundColor = UIColor.clearColor()
    }

    // pragma mark - Setters

    override var backgroundColor: UIColor? {
        didSet {
            self.leftBarButtonContainerView.backgroundColor = backgroundColor
            self.rightBarButtonContainerView.backgroundColor = backgroundColor
        }
    }

    var leftBarButtonItem: UIButton? {
        willSet (leftBarButtonItem) {
            if (self.leftBarButtonItem != nil) {
                self.leftBarButtonItem!.removeFromSuperview()
            }

            if (leftBarButtonItem == nil) {
                self.leftBarButtonItem = nil
                // self.leftHorizontalSpacingConstraint.constant = 0.0
                self.leftBarButtonItemWidth = 0.0
                self.leftBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(leftBarButtonItem!.frame, CGRectZero)) {
                leftBarButtonItem!.frame = self.leftBarButtonContainerView.bounds
            }

            self.leftBarButtonContainerView.hidden = false
            // self.leftHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
            self.leftBarButtonItemWidth = CGRectGetWidth(leftBarButtonItem!.frame)

            leftBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.leftBarButtonContainerView.addSubview(leftBarButtonItem!)
            self.leftBarButtonContainerView.gg_pinAllEdgesOfSubview(leftBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }
    
    var leftBarButtonItemWidth: CGFloat {
        set {
            // self.leftBarButtonContainerViewWidthConstraint.constant = leftBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            // return self.leftBarButtonContainerViewWidthConstraint.constant
            return 0.0
        }
    }
    
    var rightBarButtonItem: UIButton? {
        willSet (rightBarButtonItem) {
            if (self.rightBarButtonItem != nil) {
                self.rightBarButtonItem!.removeFromSuperview()
            }

            if (rightBarButtonItem == nil) {
                self.rightBarButtonItem = nil
                // self.rightHorizontalSpacingConstraint.constant = 0.0
                self.rightBarButtonItemWidth = 0.0
                self.rightBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(rightBarButtonItem!.frame, CGRectZero)) {
                rightBarButtonItem!.frame = self.rightBarButtonContainerView.bounds
            }

            self.rightBarButtonContainerView.hidden = false
            // self.rightHorizontalSpacingConstraint.constant = kMessagesToolbarContentViewHorizontalSpacingDefault
            self.rightBarButtonItemWidth = CGRectGetWidth(rightBarButtonItem!.frame)

            rightBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.rightBarButtonContainerView.addSubview(rightBarButtonItem!)
            self.rightBarButtonContainerView.gg_pinAllEdgesOfSubview(rightBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }

    var rightBarButtonItemWidth: CGFloat {
        set {
            // self.rightBarButtonContainerViewWidthConstraint.constant = rightBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            // return self.leftBarButtonContainerViewWidthConstraint.constant;
            return 0.0
        }
    }
    
    var rightContentPadding: CGFloat {
        set {
            // self.rightHorizontalSpacingConstraint.constant = rightContentPadding
            self.setNeedsUpdateConstraints()
        }
        get {
            // return self.rightHorizontalSpacingConstraint.constant
            return 0.0
        }
    }
    
    var leftContentPadding: CGFloat {
        set {
            // self.leftHorizontalSpacingConstraint.constant = leftContentPadding
            self.setNeedsUpdateConstraints()
        }
        get {
            // return self.leftHorizontalSpacingConstraint.constant
            return 0.0
        }
    }

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        // self.textView.setNeedsDisplay()
    }
}