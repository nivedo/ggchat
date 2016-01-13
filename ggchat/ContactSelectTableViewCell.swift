//
//  ContactSelectTableViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 1/13/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import UIKit

class ContactSelectTableViewCell: UITableViewCell {
   
    @IBOutlet weak var textView: UITextView!
    
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
    
        self.textView.textColor = UIColor.gg_highlightedColor()
        self.textView.text = ""
        
        self.textView.layer.borderColor = UIColor.gg_highlightedColor().CGColor
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.cornerRadius = 8.0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
