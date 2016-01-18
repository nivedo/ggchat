//
//  MessageLoadEarlierHeaderView.swift
//  ggchat
//
//  Created by Gary Chang on 11/17/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

/*
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
*/

class MessageLoadEarlierHeaderView: UICollectionReusableView {

    static let kMessagesLoadEarlierHeaderViewHeight: CGFloat = 32.0
    // var delegate: MessageLoadEarlierHeaderViewDelegate!
   
    /*
    @IBOutlet weak var loadButton: UIButton!
    @IBAction func loadButtonPressed(sender: AnyObject) {
        self.delegate.headerView(self, didPressLoadButton:sender as! UIButton)
    }
    */
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.clearColor()
       
        /*
        self.loadButton.setTitle(
            NSBundle.gg_localizedStringForKey("load_earlier_messages"),
            forState: UIControlState.Normal)
        self.loadButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        self.loadButton.setTitleColor(GGConfig.loadButtonColorNormal, forState: UIControlState.Normal)
        */
        
        self.headerLabel.text = self.headerText
        self.headerLabel.font = UIFont.systemFontOfSize(12.0)
        self.headerLabel.textColor = GGConfig.bubbleTopLabelTextColor
    }
    
    func refreshHeader() {
        self.headerLabel.text = self.headerText
        self.headerLabel.setNeedsDisplay()
    }
    
    var headerText: String {
        get {
            return XMPPMessageManager.sharedInstance.hasMoreMessagesToLoad ? NSBundle.gg_localizedStringForKey("load_earlier_messages") : "First Message"
        }
    }

    // pragma mark - Class methods

    class func nib() -> UINib {
        let nibName = NSStringFromClass(self).componentsSeparatedByString(".").last! as String
        return UINib(nibName: nibName,
            bundle: NSBundle(forClass: self))
    }

    class func headerReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }

    // pragma mark - Reusable view

    override var backgroundColor: UIColor? {
        didSet {
            self.headerLabel.backgroundColor = self.backgroundColor
        }
    }
}