//
//  MessageLabel.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageLabel: UILabel {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    var textInsets: UIEdgeInsets
    {
        set (newTextInsets)
        {
            if (UIEdgeInsetsEqualToEdgeInsets(self.textInsets, newTextInsets)) {
                return
            }
            
            self.textInsets = newTextInsets
            self.setNeedsDisplay()    
        }
        get
        {
            return self.textInsets
        }
    }
    
    func gg_configureLabel() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.textInsets = UIEdgeInsetsZero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.gg_configureLabel()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.gg_configureLabel()
    }
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(CGRectMake(CGRectGetMinX(rect) + self.textInsets.left,
        CGRectGetMinY(rect) + self.textInsets.top,
        CGRectGetWidth(rect) - self.textInsets.right,
        CGRectGetHeight(rect) - self.textInsets.bottom))
    }

}
