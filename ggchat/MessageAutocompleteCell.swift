//
//  MessageAutocompleteCell.swift
//  ggchat
//
//  Created by Gary Chang on 12/7/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageAutocompleteCell: UITableViewCell {
    
    @IBOutlet weak var cellMainLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconContainer: UIView!
    
    class func nib() -> UINib {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return UINib(nibName: nibName, bundle: NSBundle(forClass: self))
    }
    
    class func cellReuseIdentifier() -> String {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return nibName
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clearColor()
        self.cellMainLabel.textColor = UIColor.whiteColor()
        self.cellMainLabel.font = UIFont.boldSystemFontOfSize(CGFloat(16.0))
        self.separatorInset = UIEdgeInsetsMake(0.0, 40.0, 0.0, 0.0)
  
        if let resource = GGWiki.sharedInstance.wikis[GGWiki.sharedInstance.autocompleteWiki] {
            self.iconImageView.image = resource.iconImage
        }
        
        self.iconContainer.backgroundColor = UIColor.clearColor()
        self.selectionStyle = UITableViewCellSelectionStyle.None
        // self.cellMainLabel.highlightedTextColor = UIColor.darkGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
