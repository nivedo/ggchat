//
//  SettingTableAvatarCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/28/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SettingTableAvatarCell: UITableViewCell {
    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var cellTopLabel: UILabel!
    @IBOutlet weak var cellBottomLabel: UILabel!
   
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
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
