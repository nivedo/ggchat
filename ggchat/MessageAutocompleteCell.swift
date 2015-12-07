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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
