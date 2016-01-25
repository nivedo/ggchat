//
//  SettingTableMenuCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/29/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class SettingTableMenuCell: UITableViewCell {
    
    @IBOutlet weak var cellMainLabel: UILabel!
    @IBOutlet weak var cellSubLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    
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
        
        self.cellSubLabel.text = nil
        self.cellSubLabel.textColor = UIColor.lightGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func hideArrow() {
        self.arrowImageView.hidden = true
    }
    
    func showArrow() {
        self.arrowImageView.hidden = false
    }
}
