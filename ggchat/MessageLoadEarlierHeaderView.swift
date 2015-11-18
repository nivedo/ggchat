//
//  MessageLoadEarlierHeaderView.swift
//  ggchat
//
//  Created by Gary Chang on 11/17/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

protocol MessageLoadEarlierHeaderViewDelegate {
    /**
     *  Tells the delegate that the loadButton has received a touch event.
     *
     *  @param headerView The header view that contains the sender.
     *  @param sender     The button that received the touch.
     */
    func headerView(headerView: MessageLoadEarlierHeaderView,
        didPressLoadButton sender: UIButton)
}

class MessageLoadEarlierHeaderView: UICollectionReusableView {

    static let kMessagesLoadEarlierHeaderViewHeight: CGFloat = 32.0
    var delegate: MessageLoadEarlierHeaderViewDelegate!
    
    @IBOutlet weak var loadButton: UIButton!
    @IBAction func loadButtonPressed(sender: AnyObject) {
        self.delegate.headerView(self, didPressLoadButton:sender as! UIButton)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.clearColor()
        
        self.loadButton.setTitle(
            NSBundle.gg_localizedStringForKey("load_earlier_messages"),
            forState: UIControlState.Normal)
        self.loadButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }

    // pragma mark - Class methods

    class func nib() -> UINib {
        return UINib(nibName: NSStringFromClass(self),
            bundle: NSBundle(forClass: self))
    }

    class func headerReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }

    // pragma mark - Reusable view

    override var backgroundColor: UIColor? {
        didSet {
            self.loadButton.backgroundColor = self.backgroundColor
        }
    }
}