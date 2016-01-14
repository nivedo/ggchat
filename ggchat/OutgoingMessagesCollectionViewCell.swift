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
    @IBOutlet weak var arrowImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.Right;
        self.cellBottomLabel.textAlignment = NSTextAlignment.Right;
        
        self.readLabel.text = nil
        self.readLabel.font = UIFont.systemFontOfSize(10.0)
        self.readLabel.textColor = GGConfig.cellTopLabelTextColor
        
        self.arrowImageView.image = UIImage(named: "ArrowUp")
    }
    
    func mark(failedToSend: Bool, read: Bool) {
        self.resetReadLabel()
        if failedToSend {
            self.readLabel.textColor = UIColor.redColor()
            self.readLabel.text = "Send Failed"
        } else {
            if read {
                self.readLabel.text = "Read"
            } else {
                self.readLabel.text = ""
            }
        }
    }
    
    func resetReadLabel() {
        self.readLabel.font = UIFont.systemFontOfSize(10.0)
        self.readLabel.textColor = GGConfig.cellTopLabelTextColor
        self.readLabel.text = ""
    }
    
    func setIsComposing(isComposing: Bool) {
        self.arrowImageView.hidden = !isComposing
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
