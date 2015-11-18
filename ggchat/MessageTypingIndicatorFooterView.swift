//
//  MessageTypingIndicatorFooterView.swift
//  ggchat
//
//  Created by Gary Chang on 11/17/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessageTypingIndicatorFooterView: UICollectionReusableView {

    static let kMessagesTypingIndicatorFooterViewHeight: CGFloat = 46.0
    
    @IBOutlet weak var bubbleImageViewRightHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorImageViewRightHorizontalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bubbleImageView: UIImageView!
    @IBOutlet weak var typingIndicatorImageView: UIImageView!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
        self.typingIndicatorImageView.contentMode = UIViewContentMode.ScaleAspectFit
    }
    
    // pragma mark - Class methods

    class func nib() -> UINib {
        return UINib(nibName: NSStringFromClass(self),
            bundle: NSBundle(forClass: self))
    }

    class func footerReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }

    // pragma mark - Initialization
    
    override var backgroundColor: UIColor? {
        didSet {
            self.bubbleImageView.backgroundColor = self.backgroundColor
        }
    }

    // pragma mark - Typing indicator

    func configureWithEllipsisColor(ellipsisColor: UIColor,
        messageBubbleColor: UIColor,
        shouldDisplayOnLeft: Bool,
        forCollectionView collectionView: UICollectionView) {
        
        let bubbleMarginMinimumSpacing: CGFloat = 6.0
        let indicatorMarginMinimumSpacing: CGFloat = 26.0
        
        let bubbleImageFactory: MessageBubbleImageFactory = MessageBubbleImageFactory()
        
        if (shouldDisplayOnLeft) {
            self.bubbleImageView.image = bubbleImageFactory.incomingMessagesBubbleImageWithColor(messageBubbleColor).messageBubbleImage
            
            let collectionViewWidth: CGFloat = CGRectGetWidth(collectionView.frame)
            let bubbleWidth: CGFloat = CGRectGetWidth(self.bubbleImageView.frame)
            let indicatorWidth: CGFloat = CGRectGetWidth(self.typingIndicatorImageView.frame)
            
            let bubbleMarginMaximumSpacing: CGFloat = collectionViewWidth - bubbleWidth - bubbleMarginMinimumSpacing
            let indicatorMarginMaximumSpacing: CGFloat = collectionViewWidth - indicatorWidth - indicatorMarginMinimumSpacing
            
            self.bubbleImageViewRightHorizontalConstraint.constant = bubbleMarginMaximumSpacing
            self.typingIndicatorImageViewRightHorizontalConstraint.constant = indicatorMarginMaximumSpacing
        } else {
            self.bubbleImageView.image = bubbleImageFactory.outgoingMessagesBubbleImageWithColor(messageBubbleColor).messageBubbleImage
            
            self.bubbleImageViewRightHorizontalConstraint.constant = bubbleMarginMinimumSpacing
            self.typingIndicatorImageViewRightHorizontalConstraint.constant = indicatorMarginMinimumSpacing
        }
        
        self.setNeedsUpdateConstraints()
        
        self.typingIndicatorImageView.image = UIImage.gg_defaultTypingIndicatorImage().gg_imageMaskedWithColor(ellipsisColor)
    }
}
