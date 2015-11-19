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
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
    }
    
    override init(frame: CGRect) {
        print("----------------------------")
        super.init(frame: frame)
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
    }

    // required init?(coder aDecoder: NSCoder) {
    required init(coder aDecoder: NSCoder) {
        print("*****************************")
        super.init(coder: aDecoder)!
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Left
        self.cellBottomLabel.textAlignment = NSTextAlignment.Left
    }
    /*
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
        print("///////////////////////////////////")
    }
    */
}
