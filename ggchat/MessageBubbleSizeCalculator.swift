//
//  MessagesBubblesSizeCalculator.swift
//  ggchat
//
//  Created by Gary Chang on 11/12/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageBubbleSizeCalculator {

    var cache: NSCache
    var minimumBubbleWidth: CGFloat
    var usesFixedWidthBubbles: Bool
    var additionalInset: CGFloat
    var layoutWidthForFixedWidthBubbles: CGFloat


    init(cache: NSCache,
        minimumBubbleWidth: CGFloat,
        usesFixedWidthBubbles: Bool) {
        assert(minimumBubbleWidth > 0);
        self.cache = cache
        self.minimumBubbleWidth = minimumBubbleWidth
        self.usesFixedWidthBubbles = usesFixedWidthBubbles
        self.layoutWidthForFixedWidthBubbles = 0.0
        
        // this extra inset value is needed because `boundingRectWithSize:` is slightly off
        // see comment below
        self.additionalInset = 2
    }
    
    convenience init() {
        let cache = NSCache()
        cache.name = "MessagesBubblesSizeCalculator.cache"
        cache.countLimit = 200
        self.init(cache: cache,
            minimumBubbleWidth: UIImage.gg_bubbleCompactImage().size.width,
            usesFixedWidthBubbles: false)
    }

    // pragma mark - NSObject

    func description() -> String {
        return "<\(self.dynamicType): cache=\(self.cache), minimumBubbleWidth=\(self.minimumBubbleWidth), usesFixedWidthBubbles=\(self.usesFixedWidthBubbles)>"
    }

    // pragma mark - JSQMessagesBubbleSizeCalculating

    func prepareForResettingLayout(layout: MessagesCollectionViewFlowLayout) {
        self.cache.removeAllObjects()
    }
    
    func messageBubbleSizeForMessageData(messageData: Message,
        atIndexPath indexPath: NSIndexPath,
        withLayout layout: MessagesCollectionViewFlowLayout) -> CGSize {
        let cachedSize: NSValue? = self.cache.objectForKey(messageData.messageHash()) as? NSValue
        if (cachedSize != nil) {
            return cachedSize!.CGSizeValue()
        }
        
        var finalSize: CGSize = CGSizeZero
        if (messageData.isMediaMessage) {
            finalSize = messageData.media!.mediaViewDisplaySize()
        } else {
            let avatarSize: CGSize = self.gg_avatarSizeForMessageData(messageData, withLayout:layout)
            
            //  from the cell xibs, there is a 2 point space between avatar and bubble
            // let spacingBetweenAvatarAndBubble: CGFloat = 2.0
            let spacingBetweenAvatarAndBubble: CGFloat = 0.0
            let horizontalContainerInsets: CGFloat = layout.messageBubbleTextViewTextContainerInsets.left + layout.messageBubbleTextViewTextContainerInsets.right
            let horizontalFrameInsets: CGFloat = layout.messageBubbleTextViewFrameInsets.left + layout.messageBubbleTextViewFrameInsets.right
            
            let horizontalInsetsTotal: CGFloat = horizontalContainerInsets + horizontalFrameInsets + spacingBetweenAvatarAndBubble
            let maximumTextWidth: CGFloat = self.textBubbleWidthForLayout(layout) - avatarSize.width - layout.messageBubbleLeftRightMargin - horizontalInsetsTotal
            
            let stringRect: CGRect = messageData.displayText.boundingRectWithSize(
                CGSizeMake(maximumTextWidth, CGFloat.max),
                options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions.UsesLineFragmentOrigin.rawValue | NSStringDrawingOptions.UsesFontLeading.rawValue ),
                attributes: [ NSFontAttributeName : layout.messageBubbleFont ],
                context: nil)
            
            let stringSize: CGSize = CGRectIntegral(stringRect).size;
            
            let verticalContainerInsets: CGFloat = layout.messageBubbleTextViewTextContainerInsets.top + layout.messageBubbleTextViewTextContainerInsets.bottom
            let verticalFrameInsets: CGFloat = layout.messageBubbleTextViewFrameInsets.top + layout.messageBubbleTextViewFrameInsets.bottom
            
            //  add extra 2 points of space (`self.additionalInset`), because `boundingRectWithSize:` is slightly off
            //  not sure why. magix. (shrug) if you know, submit a PR
            let verticalInsets: CGFloat = verticalContainerInsets + verticalFrameInsets + self.additionalInset
            
            //  same as above, an extra 2 points of magix
            let finalWidth: CGFloat = max(stringSize.width + horizontalInsetsTotal, self.minimumBubbleWidth) + self.additionalInset
            
            finalSize = CGSizeMake(finalWidth, stringSize.height + verticalInsets)
        }
        
        self.cache.setObject(NSValue(CGSize: finalSize), forKey: messageData.messageHash());
    
        return finalSize;
    }
    
    func gg_avatarSizeForMessageData(messageData: Message,
        withLayout layout: MessagesCollectionViewFlowLayout) -> CGSize {
        let messageSender: String = messageData.senderId
        
        if (messageSender == layout.messageCollectionView.messageDataSource.senderId) {
            return layout.outgoingAvatarViewSize
        }
        
        return layout.incomingAvatarViewSize
    }
    
    func textBubbleWidthForLayout(layout: MessagesCollectionViewFlowLayout) -> CGFloat {
        if (self.usesFixedWidthBubbles) {
            return self.widthForFixedWidthBubblesWithLayout(layout)
        }
        
        return layout.itemWidth
    }
    
    func widthForFixedWidthBubblesWithLayout(layout: MessagesCollectionViewFlowLayout) -> CGFloat {
        if (self.layoutWidthForFixedWidthBubbles > 0.0) {
            return self.layoutWidthForFixedWidthBubbles
        }
        
        // also need to add `self.additionalInset` here, see comment above
        let horizontalInsets: CGFloat = layout.sectionInset.left + layout.sectionInset.right + self.additionalInset
        let width: CGFloat = CGRectGetWidth(layout.messageCollectionView.bounds) - horizontalInsets
        let height: CGFloat = CGRectGetHeight(layout.messageCollectionView.bounds) - horizontalInsets
        self.layoutWidthForFixedWidthBubbles = min(width, height)
        
        return self.layoutWidthForFixedWidthBubbles
    }
}
