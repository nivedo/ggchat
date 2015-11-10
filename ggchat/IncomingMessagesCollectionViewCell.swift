//
//  IncomingMessagesCollectionViewCell.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class IncomingMessagesCollectionViewCell: MessagesCollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left;
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left;
    }

}
