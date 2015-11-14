//
//  MessagesCollectionViewLayoutAttributes.swift
//  ggchat
//
//  Created by Gary Chang on 11/12/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

    // pragma mark - Setters
    
    var messageBubbleFont: UIFont {
        set (newMessageBubbleFont) {
            self.messageBubbleFont = newMessageBubbleFont
        }
        get {
            return self.messageBubbleFont
        }
    }
    
    var messageBubbleContainerViewWidth: CGFloat {
        set (newMessageBubbleContainerViewWidth) {
            assert(newMessageBubbleContainerViewWidth > 0.0)
            self.messageBubbleContainerViewWidth = ceil(newMessageBubbleContainerViewWidth)
        }
        get {
            return self.messageBubbleContainerViewWidth
        }
    }
    
    var incomingAvatarViewSize: CGSize {
        set (newIncomingAvatarViewSize) {
            assert(newIncomingAvatarViewSize.width >= 0.0 && newIncomingAvatarViewSize.height >= 0.0)
            self.incomingAvatarViewSize = self.gg_correctedAvatarSizeFromSize(newIncomingAvatarViewSize)
        }
        get {
            return self.incomingAvatarViewSize
        }
    }
    
    var outgoingAvatarViewSize: CGSize {
        set (newOutgoingAvatarViewSize) {
            assert(newOutgoingAvatarViewSize.width >= 0.0 && newOutgoingAvatarViewSize.height >= 0.0)
            self.outgoingAvatarViewSize = self.gg_correctedAvatarSizeFromSize(newOutgoingAvatarViewSize)
        }
        get {
            return self.outgoingAvatarViewSize
        }
    }
    
    var cellTopLabelHeight: CGFloat {
        set (newCellTopLabelHeight) {
            assert(newCellTopLabelHeight >= 0.0)
            self.cellTopLabelHeight = self.gg_correctedLabelHeightForHeight(newCellTopLabelHeight)
        }
        get {
            return self.cellTopLabelHeight
        }
    }
    
    var messageBubbleTopLabelHeight: CGFloat {
        set (newMessageBubbleTopLabelHeight) {
            assert(newMessageBubbleTopLabelHeight >= 0.0)
            self.messageBubbleTopLabelHeight = self.gg_correctedLabelHeightForHeight(newMessageBubbleTopLabelHeight)
        }
        get {
            return self.messageBubbleTopLabelHeight
        }
    }
    
    var cellBottomLabelHeight: CGFloat {
        set(newCellBottomLabelHeight) {
            assert(newCellBottomLabelHeight >= 0.0)
            self.cellBottomLabelHeight = self.gg_correctedLabelHeightForHeight(newCellBottomLabelHeight)
        }
        get {
            return self.cellBottomLabelHeight
        }
    }
    
    // pragma mark - Utilities
    
    func gg_correctedAvatarSizeFromSize(size: CGSize) -> CGSize {
        return CGSizeMake(ceil(size.width), ceil(size.height))
    }
    
    func gg_correctedLabelHeightForHeight(height: CGFloat) -> CGFloat {
        return ceil(height)
    }
    
    // pragma mark - NSObject
    
    func isEqual(id object: NSObject) -> Bool {
        if (self == object) {
            return true
        }
        
        if (!object.isKindOfClass(self.dynamicType)) {
            return false
        }
        
        if (self.representedElementCategory == UICollectionElementCategory.Cell) {
            let layoutAttributes: MessagesCollectionViewLayoutAttributes = object as! MessagesCollectionViewLayoutAttributes
            
            if (!layoutAttributes.messageBubbleFont.isEqual(self.messageBubbleFont)
                || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewFrameInsets, self.textViewFrameInsets)
                || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewTextContainerInsets, self.textViewTextContainerInsets)
                || !CGSizeEqualToSize(layoutAttributes.incomingAvatarViewSize, self.incomingAvatarViewSize)
                || !CGSizeEqualToSize(layoutAttributes.outgoingAvatarViewSize, self.outgoingAvatarViewSize)
                || Int(layoutAttributes.messageBubbleContainerViewWidth) != Int(self.messageBubbleContainerViewWidth)
                || Int(layoutAttributes.cellTopLabelHeight) != Int(self.cellTopLabelHeight)
                || Int(layoutAttributes.messageBubbleTopLabelHeight) != Int(self.messageBubbleTopLabelHeight)
                || Int(layoutAttributes.cellBottomLabelHeight) != Int(self.cellBottomLabelHeight)) {
                return false
            }
        }
        
        return super.isEqual(object)
    }
    
    func hash() -> Int {
        return self.indexPath.hash
    }
    
    // pragma mark - NSCopying
    
    func copyWithZone(zone: NSZone) -> MessagesCollectionViewLayoutAttributes {
        let copy: MessagesCollectionViewLayoutAttributes = super.copyWithZone(zone)
        
        if (copy.representedElementCategory != UICollectionElementCategory.Cell) {
            return copy
        }
        
        copy.messageBubbleFont = self.messageBubbleFont
        copy.messageBubbleContainerViewWidth = self.messageBubbleContainerViewWidth
        copy.textViewFrameInsets = self.textViewFrameInsets
        copy.textViewTextContainerInsets = self.textViewTextContainerInsets
        copy.incomingAvatarViewSize = self.incomingAvatarViewSize
        copy.outgoingAvatarViewSize = self.outgoingAvatarViewSize
        copy.cellTopLabelHeight = self.cellTopLabelHeight
        copy.messageBubbleTopLabelHeight = self.messageBubbleTopLabelHeight
        copy.cellBottomLabelHeight = self.cellBottomLabelHeight
        
        return copy;
    }
}
