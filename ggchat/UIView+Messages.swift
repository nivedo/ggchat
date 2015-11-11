//
//  UIView+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func gg_pinSubview(subview: UIView, toEdge attribute: NSLayoutAttribute) {
        self.addConstraint(NSLayoutConstraint(
            item: self,
            attribute: attribute,
            relatedBy: NSLayoutRelation.Equal,
            toItem: subview,
            attribute: attribute,
            multiplier: 1.0,
            constant: 0.0))
    }
    
    func gg_pinAllEdgesOfSubview(subview: UIView) {
        self.gg_pinSubview(subview, toEdge:NSLayoutAttribute.Bottom)
        self.gg_pinSubview(subview, toEdge:NSLayoutAttribute.Top)
        self.gg_pinSubview(subview, toEdge:NSLayoutAttribute.Leading)
        self.gg_pinSubview(subview, toEdge:NSLayoutAttribute.Trailing)
    }
}