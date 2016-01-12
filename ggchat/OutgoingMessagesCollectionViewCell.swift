//
//  OutgoingMessagesCollectionViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class OutgoingMessagesCollectionViewCell: MessagesCollectionViewCell {

    @IBOutlet weak var readLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right;
        self.cellBottomLabel.textAlignment = NSTextAlignment.Right;
        
        self.readLabel.text = nil
        self.readLabel.font = UIFont.systemFontOfSize(10.0)
        self.readLabel.textColor = GGConfig.cellTopLabelTextColor
    }
    
    func markAsRead(read: Bool) {
        if read {
            self.readLabel.text = "Read"
        } else {
            self.readLabel.text = ""
        }
    }
    
    /*
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right
        self.cellBottomLabel.textAlignment = NSTextAlignment.Right
    }

    // required init?(coder aDecoder: NSCoder) {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        // self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right
        // self.cellBottomLabel.textAlignment = NSTextAlignment.Right
    }
    */
}
