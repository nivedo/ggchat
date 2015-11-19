//
//  MessagesCollectionViewLayoutAttributes.swift
//  ggchat
//
//  Created by Gary Chang on 11/12/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var textViewFrameInsets: UIEdgeInsets?
    var textViewTextContainerInsets: UIEdgeInsets?
    
    // pragma mark - Setters
    
    var messageBubbleFont: UIFont!
    var messageBubbleContainerViewWidth: CGFloat = 0 {
        willSet {
            assert(newValue >= 0.0)
        }
    }
    
    var incomingAvatarViewSize: CGSize = CGSizeMake(0, 0) {
        willSet {
            assert(newValue.width >= 0.0 && newValue.height >= 0.0)
            self.incomingAvatarViewSize = self.gg_correctedAvatarSizeFromSize(newValue)
        }
    }
    var outgoingAvatarViewSize: CGSize = CGSizeMake(0, 0) {
        willSet {
            assert(newValue.width >= 0.0 && newValue.height >= 0.0)
            self.outgoingAvatarViewSize = self.gg_correctedAvatarSizeFromSize(newValue)
        }
    }
    
    var cellTopLabelHeight: CGFloat = 0 {
        didSet {
            assert(self.cellTopLabelHeight >= 0.0)
            self.cellTopLabelHeight = self.gg_correctedLabelHeightForHeight(self.cellTopLabelHeight)
        }
    }
    
    var messageBubbleTopLabelHeight: CGFloat = 0 {
        didSet {
            assert(self.messageBubbleTopLabelHeight >= 0.0)
            self.messageBubbleTopLabelHeight = self.gg_correctedLabelHeightForHeight(self.messageBubbleTopLabelHeight)
        }
    }
    
    var cellBottomLabelHeight: CGFloat = 0 {
        didSet {
            assert(self.cellBottomLabelHeight >= 0.0)
            self.cellBottomLabelHeight = self.gg_correctedLabelHeightForHeight(self.cellBottomLabelHeight)
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
                || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewFrameInsets!, self.textViewFrameInsets!)
                || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewTextContainerInsets!, self.textViewTextContainerInsets!)
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
    
    override var hash: Int {
        get {
            return self.indexPath.hash
        }
    }
    
    // pragma mark - NSCopying
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: MessagesCollectionViewLayoutAttributes = super.copyWithZone(zone) as! MessagesCollectionViewLayoutAttributes
        
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
