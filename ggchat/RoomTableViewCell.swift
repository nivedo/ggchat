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
        return NSStringFromClass(self).componentsSeparatedByString(".").last! as String
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    
        self.cellTopLabel.text = nil
        self.cellBottomLabel.text = nil
        self.cellCornerLabel.text = nil
        
        self.avatarImageView.image = nil
        self.avatarImageView.highlightedImage = nil
    }
    
    override func awakeFromNib() {
        print("awakeFromNib()")
        super.awakeFromNib()
        
        // Initialization code
        self.translatesAutoresizingMaskIntoConstraints = false
        
        /*
        self.cellTopLabelHeightConstraint.constant = 0.0
        self.cellBottomLabelHeightConstraint.constant = 0.0
        
        self.avatarViewSize = CGSizeZero
        */
        
        self.cellTopLabel.textAlignment = NSTextAlignment.Left
        self.cellTopLabel.font = UIFont.boldSystemFontOfSize(20.0)
        self.cellTopLabel.textColor = UIColor.darkGrayColor()
        
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.font = UIFont.systemFontOfSize(18.0)
        self.cellBottomLabel.textColor = UIColor.lightGrayColor()
        
        self.cellCornerLabel.textAlignment = NSTextAlignment.Right
        self.cellCornerLabel.font = UIFont.systemFontOfSize(16.0)
        self.cellCornerLabel.textColor = UIColor.lightGrayColor()
        
        // Selection colors
        self.selectionStyle = UITableViewCellSelectionStyle.Default
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.lightGrayColor()
        self.selectedBackgroundView = bgColorView
        self.backgroundColor = GGConfig.backgroundColor
        
        // Get rid of inset
        self.layoutMargins = UIEdgeInsetsZero
        self.preservesSuperviewLayoutMargins = false
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        print("selected")
    }
    
}
