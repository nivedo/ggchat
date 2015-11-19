//
//  OutgoingMessagesCollectionViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class OutgoingMessagesCollectionViewCell: MessagesCollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right;
        self.cellBottomLabel.textAlignment = NSTextAlignment.Right;
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
