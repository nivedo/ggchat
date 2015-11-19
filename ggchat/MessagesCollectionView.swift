//
//  MessagesCollectionView.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionView:
    UICollectionView,
    MessageCollectionViewCellDelegate,
    MessageLoadEarlierHeaderViewDelegate {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    var messageDelegate: MessageViewController { return self.delegate as! MessageViewController }
    var messageDataSource: MessageViewController { return self.dataSource as! MessageViewController }
    var messageCollectionViewLayout: MessagesCollectionViewFlowLayout { return self.collectionViewLayout as! MessagesCollectionViewFlowLayout }

    var typingIndicatorDisplaysOnLeft: Bool = true
    var typingIndicatorMessageBubbleColor: UIColor = UIColor.gg_messageBubbleLightGrayColor()
    var typingIndicatorEllipsisColor: UIColor = UIColor.gg_messageBubbleLightGrayColor().gg_colorByDarkeningColorWithValue(0.3)
    var loadEarlierMessagesHeaderTextColor: UIColor = UIColor.gg_messageBubbleBlueColor()
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        print("MessagesCollectionView:init(frame:,layout:)")
        self.gg_configureCollectionView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("MessagesCollectionView:init(coder:)")
        self.gg_configureCollectionView()
    }
    
    override func awakeFromNib() {
        print("MessagesCollectionView:awakeFromNib()")
        super.awakeFromNib()
        self.gg_configureCollectionView()
    }
    
    func gg_configureCollectionView() {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.backgroundColor = UIColor.whiteColor()
        self.keyboardDismissMode = UIScrollViewKeyboardDismissMode.None
        self.alwaysBounceVertical = true
        self.bounces = true
        self.messageCollectionViewLayout.messageCollectionView = self
        
        self.registerNib(IncomingMessagesCollectionViewCell.nib(),
            forCellWithReuseIdentifier: IncomingMessagesCollectionViewCell.cellReuseIdentifier())
        self.registerNib(OutgoingMessagesCollectionViewCell.nib(),
            forCellWithReuseIdentifier: OutgoingMessagesCollectionViewCell.cellReuseIdentifier())
        
        self.registerNib(UINib(nibName: "IncomingMessagesCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: IncomingMessagesCollectionViewCell.mediaCellReuseIdentifier())
        self.registerNib(UINib(nibName: "OutgoingMessagesCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: OutgoingMessagesCollectionViewCell.mediaCellReuseIdentifier())
        
        self.registerNib(MessageTypingIndicatorFooterView.nib(),
            forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
            withReuseIdentifier: MessageTypingIndicatorFooterView.footerReuseIdentifier())
        
        self.registerNib(MessageLoadEarlierHeaderView.nib(),
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
            withReuseIdentifier: MessageLoadEarlierHeaderView.headerReuseIdentifier())
    }

    // pragma mark - Typing indicator
    func dequeueTypingIndicatorFooterViewForIndexPath(indexPath: NSIndexPath) -> MessageTypingIndicatorFooterView {
        let footerView: MessageTypingIndicatorFooterView = super.dequeueReusableSupplementaryViewOfKind(
                UICollectionElementKindSectionFooter,
                withReuseIdentifier: MessageTypingIndicatorFooterView.footerReuseIdentifier(),
                forIndexPath: indexPath) as! MessageTypingIndicatorFooterView

        footerView.configureWithEllipsisColor(
            self.typingIndicatorEllipsisColor,
            messageBubbleColor: self.typingIndicatorMessageBubbleColor,
            shouldDisplayOnLeft: self.typingIndicatorDisplaysOnLeft,
            forCollectionView: self)

        return footerView
    }

    // pragma mark - Load earlier messages header

    func dequeueLoadEarlierMessagesViewHeaderForIndexPath(indexPath: NSIndexPath) -> MessageLoadEarlierHeaderView {
        let headerView: MessageLoadEarlierHeaderView = super.dequeueReusableSupplementaryViewOfKind(
            UICollectionElementKindSectionHeader,
            withReuseIdentifier: MessageLoadEarlierHeaderView.headerReuseIdentifier(),
            forIndexPath: indexPath) as! MessageLoadEarlierHeaderView

        headerView.loadButton.tintColor = self.loadEarlierMessagesHeaderTextColor
        headerView.delegate = self

        return headerView
    }
    
    // pragma mark - Load earlier messages header delegate

    func headerView(headerView: MessageLoadEarlierHeaderView, didPressLoadButton sender:UIButton) {
        if (self.messageDelegate.respondsToSelector(Selector("collectionView:header:didTapLoadEarlierMessagesButton:"))) {
            self.messageDelegate.collectionView(self,
                header: headerView,
                didTapLoadEarlierMessagesButton: sender)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    // MessageCollectionViewCellDelegate
    //////////////////////////////////////////////////////////////////////////////////

    func messagesCollectionViewCellDidTapAvatar(cell: MessagesCollectionViewCell) {
        let indexPath: NSIndexPath? = self.indexPathForCell(cell)
        if (indexPath == nil) {
            return
        }

        self.messageDelegate.collectionView(self,
            didTapAvatarImageView: cell.avatarImageView,
            atIndexPath: indexPath!)
    }

    func messagesCollectionViewCellDidTapMessageBubble(cell: MessagesCollectionViewCell) {
        let indexPath: NSIndexPath? = self.indexPathForCell(cell)
        if (indexPath == nil) {
            return
        }

        self.messageDelegate.collectionView(self, didTapMessageBubbleAtIndexPath:indexPath!)
    }

    func messagesCollectionViewCellDidTapCell(cell: MessagesCollectionViewCell,
        atPosition position: CGPoint) {
        let indexPath: NSIndexPath? = self.indexPathForCell(cell)
        if (indexPath == nil) {
            return
        }

        self.messageDelegate.collectionView(self,
            didTapCellAtIndexPath: indexPath!,
            touchLocation: position)
    }

    func messagesCollectionViewCell(cell: MessagesCollectionViewCell,
        didPerformAction action: Selector,
        withSender sender: AnyObject?) {
        let indexPath: NSIndexPath? = self.indexPathForCell(cell)
        if (indexPath == nil) {
            return
        }

        self.messageDelegate.collectionView(self,
            performAction: action,
            forItemAtIndexPath: indexPath!,
            withSender: sender)
    }
}
