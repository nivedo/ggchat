//
//  ChatTableViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import CustomBadge

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var badgeContainer: UIView!
    
    @IBOutlet weak var cellTopLabel: UILabel!
    @IBOutlet weak var cellBottomLabel: UILabel!
    @IBOutlet weak var cellCornerLabel: UILabel!

    var badge: CustomBadge? {
        willSet {
            if let badge = self.badge {
                badge.removeFromSuperview()
            }
        }
        didSet {
            if let badge = self.badge {
                self.badgeContainer.addSubview(badge)
            }
        }
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
        super.awakeFromNib()
   
        // Initialization code
        // self.translatesAutoresizingMaskIntoConstraints = false
        
        self.cellTopLabel.textAlignment = NSTextAlignment.Left
        self.cellTopLabel.font = UIFont.boldSystemFontOfSize(20.0)
        self.cellTopLabel.textColor = UIColor.darkGrayColor()
        self.cellTopLabel.adjustsFontSizeToFitWidth = false
        self.cellTopLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.font = UIFont.systemFontOfSize(18.0)
        self.cellBottomLabel.textColor = UIColor.lightGrayColor()
        self.cellBottomLabel.adjustsFontSizeToFitWidth = false
        self.cellBottomLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        
        self.cellCornerLabel.textAlignment = NSTextAlignment.Right
        self.cellCornerLabel.font = UIFont.systemFontOfSize(16.0)
        self.cellCornerLabel.textColor = UIColor.lightGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
