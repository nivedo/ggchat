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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
