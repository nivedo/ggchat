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

    static let kMessagesToolbarContentViewHorizontalSpacingDefault: CGFloat = 8.0
    @IBOutlet weak var leftBarButtonContainerView: UIView!
    @IBOutlet weak var leftInnerBarButtonContainerView: UIView!
    @IBOutlet weak var rightBarButtonContainerView: UIView!
    @IBOutlet weak var rightInnerBarButtonContainerView: UIView!
    @IBOutlet weak var textView: MessageComposerTextView!
    
    @IBOutlet weak var leftBarButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftInnerBarButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightBarButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightInnerBarButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftHorizontalSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHorizontalSpacingConstraint: NSLayoutConstraint!

    // pragma mark - Class methods
    class func nib() -> UINib {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return UINib(nibName: nibName,
            bundle: NSBundle(forClass: self))
    }
    
    // pragma mark - Initialization

    override func awakeFromNib() {
        // print("ToolbarContentView::awakeFromNib()")
        super.awakeFromNib()

        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.leftHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
        self.rightHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
        
        // self.backgroundColor = UIColor.clearColor()
        self.backgroundColor = UIColor.whiteColor()
        // self.userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("MessageToolbarContentView::init(coder:)")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("MessageToolbarContentView::init(rect:)")
    }

    // pragma mark - Setters
    override var backgroundColor: UIColor? {
        didSet {
            if (self.leftBarButtonContainerView != nil) {
                self.leftBarButtonContainerView.backgroundColor = backgroundColor
            }
            if (self.leftInnerBarButtonContainerView != nil) {
                self.leftInnerBarButtonContainerView.backgroundColor = backgroundColor
            }
            if (self.rightBarButtonContainerView != nil) {
                self.rightBarButtonContainerView.backgroundColor = backgroundColor
            }
            if (self.rightInnerBarButtonContainerView != nil) {
                self.rightInnerBarButtonContainerView.backgroundColor = backgroundColor
            }
        }
    }

    dynamic var leftBarButtonItem: UIButton? {
        willSet (leftBarButtonItem) {
            if (self.leftBarButtonItem != nil) {
                self.leftBarButtonItem!.removeFromSuperview()
            }

            if (leftBarButtonItem == nil) {
                self.leftBarButtonItem = nil
                self.leftHorizontalSpacingConstraint.constant = 0.0
                self.leftBarButtonItemWidth = 0.0
                self.leftBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(leftBarButtonItem!.frame, CGRectZero)) {
                leftBarButtonItem!.frame = self.leftBarButtonContainerView.bounds
            }

            self.leftBarButtonContainerView.hidden = false
            self.leftHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
            self.leftBarButtonItemWidth = CGRectGetWidth(leftBarButtonItem!.frame)

            leftBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.leftBarButtonContainerView.addSubview(leftBarButtonItem!)
            self.leftBarButtonContainerView.gg_pinAllEdgesOfSubview(leftBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }
    
    dynamic var leftInnerBarButtonItem: UIButton? {
        willSet (leftInnerBarButtonItem) {
            if (self.leftInnerBarButtonItem != nil) {
                self.leftInnerBarButtonItem!.removeFromSuperview()
            }

            if (leftInnerBarButtonItem == nil) {
                self.leftInnerBarButtonItem = nil
                self.leftHorizontalSpacingConstraint.constant = 0.0
                self.leftInnerBarButtonItemWidth = 0.0
                self.leftInnerBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(leftInnerBarButtonItem!.frame, CGRectZero)) {
                leftInnerBarButtonItem!.frame = self.leftInnerBarButtonContainerView.bounds
            }

            self.leftInnerBarButtonContainerView.hidden = false
            self.leftHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
            self.leftInnerBarButtonItemWidth = CGRectGetWidth(leftInnerBarButtonItem!.frame)

            leftInnerBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.leftInnerBarButtonContainerView.addSubview(leftInnerBarButtonItem!)
            self.leftInnerBarButtonContainerView.gg_pinAllEdgesOfSubview(leftInnerBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }
    
    dynamic var rightInnerBarButtonItem: UIButton? {
        willSet (rightInnerBarButtonItem) {
            if (self.rightInnerBarButtonItem != nil) {
                self.rightInnerBarButtonItem!.removeFromSuperview()
            }

            if (rightInnerBarButtonItem == nil) {
                self.rightInnerBarButtonItem = nil
                self.rightHorizontalSpacingConstraint.constant = 0.0
                self.rightInnerBarButtonItemWidth = 0.0
                self.rightInnerBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(rightInnerBarButtonItem!.frame, CGRectZero)) {
                rightInnerBarButtonItem!.frame = self.rightInnerBarButtonContainerView.bounds
            }

            self.rightInnerBarButtonContainerView.hidden = false
            self.rightHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
            self.rightInnerBarButtonItemWidth = CGRectGetWidth(rightInnerBarButtonItem!.frame)

            rightInnerBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.rightInnerBarButtonContainerView.addSubview(rightInnerBarButtonItem!)
            self.rightInnerBarButtonContainerView.gg_pinAllEdgesOfSubview(rightInnerBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }
    
    var leftBarButtonItemWidth: CGFloat {
        set {
            self.leftBarButtonContainerViewWidthConstraint.constant = leftBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.leftBarButtonContainerViewWidthConstraint.constant
        }
    }
    
    var leftInnerBarButtonItemWidth: CGFloat {
        set {
            self.leftInnerBarButtonContainerViewWidthConstraint.constant = leftInnerBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.leftInnerBarButtonContainerViewWidthConstraint.constant
        }
    }
    
    var rightInnerBarButtonItemWidth: CGFloat {
        set {
            self.rightInnerBarButtonContainerViewWidthConstraint.constant = rightInnerBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.rightInnerBarButtonContainerViewWidthConstraint.constant
        }
    }
    
    dynamic var rightBarButtonItem: UIButton? {
        willSet (rightBarButtonItem) {
            if (self.rightBarButtonItem != nil) {
                self.rightBarButtonItem!.removeFromSuperview()
            }

            if (rightBarButtonItem == nil) {
                self.rightBarButtonItem = nil
                self.rightHorizontalSpacingConstraint.constant = 0.0
                self.rightBarButtonItemWidth = 0.0
                self.rightBarButtonContainerView.hidden = true
                return
            }

            if (CGRectEqualToRect(rightBarButtonItem!.frame, CGRectZero)) {
                rightBarButtonItem!.frame = self.rightBarButtonContainerView.bounds
            }

            self.rightBarButtonContainerView.hidden = false
            self.rightHorizontalSpacingConstraint.constant = MessageToolbarContentView.kMessagesToolbarContentViewHorizontalSpacingDefault
            self.rightBarButtonItemWidth = CGRectGetWidth(rightBarButtonItem!.frame)

            rightBarButtonItem!.translatesAutoresizingMaskIntoConstraints = false

            self.rightBarButtonContainerView.addSubview(rightBarButtonItem!)
            self.rightBarButtonContainerView.gg_pinAllEdgesOfSubview(rightBarButtonItem!)
            self.setNeedsUpdateConstraints()
        }
    }

    var rightBarButtonItemWidth: CGFloat {
        set {
            self.rightBarButtonContainerViewWidthConstraint.constant = rightBarButtonItemWidth
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.rightBarButtonContainerViewWidthConstraint.constant;
        }
    }
    
    var rightContentPadding: CGFloat {
        set {
            self.rightHorizontalSpacingConstraint.constant = rightContentPadding
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.rightHorizontalSpacingConstraint.constant
        }
    }
    
    var leftContentPadding: CGFloat {
        set {
            self.leftHorizontalSpacingConstraint.constant = leftContentPadding
            self.setNeedsUpdateConstraints()
        }
        get {
            return self.leftHorizontalSpacingConstraint.constant
        }
    }
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        if (self.textView != nil) {
            self.textView.setNeedsDisplay()
        }
    }
}