//
//  RoomTableViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/20/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cellTopLabel: UILabel!
    @IBOutlet weak var cellBottomLabel: UILabel!
    @IBOutlet weak var cellCornerLabel: UILabel!
    
    class func nib() -> UINib {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return UINib(nibName: nibName, bundle: NSBundle(forClass: self))
    }
    
    class func cellReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = GGConfig.backgroundColor // UIColor.whiteColor()
        
        /*
        self.cellTopLabelHeightConstraint.constant = 0.0
        self.cellBottomLabelHeightConstraint.constant = 0.0
        
        self.avatarViewSize = CGSizeZero
        */
        
        self.cellTopLabel.textAlignment = NSTextAlignment.Left
        self.cellTopLabel.font = UIFont.boldSystemFontOfSize(12.0)
        self.cellTopLabel.textColor = UIColor.darkGrayColor()
        
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.font = UIFont.systemFontOfSize(11.0)
        self.cellBottomLabel.textColor = UIColor.lightGrayColor()
        
        self.cellCornerLabel.textAlignment = NSTextAlignment.Right
        self.cellCornerLabel.font = UIFont.systemFontOfSize(10.0)
        self.cellCornerLabel.textColor = UIColor.lightGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
