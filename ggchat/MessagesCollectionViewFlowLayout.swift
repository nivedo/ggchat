//
//  MessagesCollectionViewFlowLayout.swift
//  ggchat
//
//  Created by Gary Chang on 11/11/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    let kMessagesCollectionViewCellLabelHeightDefault: CGFloat = 20.0
    let kMessagesCollectionViewAvatarSizeDefault: CGFloat = 30.0
    
    var messagesCollectionView: MessagesCollectionView?
    override var collectionView: MessagesCollectionView {
        get {
            return self.messagesCollectionView!
        }
    }
    
    // pragma mark - Getters
    
    var dynamicAnimator: UIDynamicAnimator? {
        get {
            if (self.dynamicAnimator == nil) {
                self.dynamicAnimator = UIDynamicAnimator(collectionViewLayout:self)
            }
            return self.dynamicAnimator
        }
        set (newDynamicAnimator) {
            self.dynamicAnimator = newDynamicAnimator
        }
    }
    var visibleIndexPaths: NSMutableSet = NSMutableSet()

    var itemWidth : CGFloat {
        get {
            return CGRectGetWidth(self.collectionView.frame) - self.sectionInset.left - self.sectionInset.right;
        }
    }
  
    var latestDelta: CGFloat = 0.0
    var messageBubbleTextViewFrameInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 6.0)
    var springResistanceFactor: CGFloat = 1000

    var springinessEnabled: Bool {
        get {
            return self.springinessEnabled
        }
        set (newSpringinessEnabled) {
            if (self.springinessEnabled == newSpringinessEnabled) {
                return
            }
                
            self.springinessEnabled = newSpringinessEnabled
            
            if (!self.springinessEnabled) {
                self.dynamicAnimator!.removeAllBehaviors()
                self.visibleIndexPaths.removeAllObjects()
            }
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }

    var messageBubbleFont: UIFont {
        set (newMessageBubbleFont) {
            if (self.messageBubbleFont.isEqual(newMessageBubbleFont)) {
                return;
            }
            self.messageBubbleFont = newMessageBubbleFont
        self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
        get {
            return self.messageBubbleFont
        }
    }

    var messageBubbleLeftRightMargin: CGFloat {
        set (newMessageBubbleLeftRightMargin) {
            assert(newMessageBubbleLeftRightMargin >= 0.0)
            self.messageBubbleLeftRightMargin = CGFloat(ceilf(Float(newMessageBubbleLeftRightMargin)))
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
        get {
            return self.messageBubbleLeftRightMargin
        }
    }

    var messageBubbleTextViewTextContainerInsets: UIEdgeInsets {
        set (newMessageBubbleTextViewTextContainerInsets) {
            if (UIEdgeInsetsEqualToEdgeInsets(self.messageBubbleTextViewTextContainerInsets, newMessageBubbleTextViewTextContainerInsets)) {
                return
            }
            
            self.messageBubbleTextViewTextContainerInsets = newMessageBubbleTextViewTextContainerInsets
            self.invalidateLayoutWithContext (MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
        get {
            return self.messageBubbleTextViewTextContainerInsets
        }
    }
    
    var incomingAvatarViewSize: CGSize {
        set (newIncomingAvatarViewSize) {
            if (CGSizeEqualToSize(self.incomingAvatarViewSize, newIncomingAvatarViewSize)) {
                return
            }
            
            self.incomingAvatarViewSize = newIncomingAvatarViewSize
        self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
        get {
            return self.incomingAvatarViewSize
        }
    }
    
    var outgoingAvatarViewSize: CGSize {
        set (newOutgoingAvatarViewSize) {
            if (CGSizeEqualToSize(self.outgoingAvatarViewSize, newOutgoingAvatarViewSize)) {
                return
            }
            
            self.outgoingAvatarViewSize = newOutgoingAvatarViewSize
        self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
        get {
            return self.outgoingAvatarViewSize
        }
    }

    func gg_configureFlowLayout() {
        self.scrollDirection = UICollectionViewScrollDirection.Vertical
        self.sectionInset = UIEdgeInsetsMake(10.0, 4.0, 10.0, 4.0)
        self.minimumLineSpacing = 4.0
        
        self.messageBubbleFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        if (UIDevice.currentDevice().userInterfaceIdiom == .Pad) {
            self.messageBubbleLeftRightMargin = 240.0
        } else {
            self.messageBubbleLeftRightMargin = 50.0
        }
        
        self.messageBubbleTextViewFrameInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 6.0)
        self.messageBubbleTextViewTextContainerInsets = UIEdgeInsetsMake(7.0, 14.0, 7.0, 14.0)
        
        let defaultAvatarSize: CGSize = CGSizeMake(kMessagesCollectionViewAvatarSizeDefault, kMessagesCollectionViewAvatarSizeDefault)
        self.incomingAvatarViewSize = defaultAvatarSize
        self.outgoingAvatarViewSize = defaultAvatarSize
        
        self.springinessEnabled = false
        self.springResistanceFactor = 1000
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "gg_didReceiveApplicationMemoryWarningNotification:",
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "gg_didReceiveDeviceOrientationDidChangeNotification:",
            name: UIDeviceOrientationDidChangeNotification,
            object: nil)
    }
    
    override init() {
        print("MessagesCollectionViewFlowLayout::init()")
        super.init()
        self.gg_configureFlowLayout()
    }
    
    required init?(coder: NSCoder) {
        print("MessagesCollectionViewFlowLayout::init(coder:)")
        super.init(coder: coder)
        self.gg_configureFlowLayout()
    }

    override func awakeFromNib() {
        print("MessagesCollectionViewFlowLayout::awakeFromNib()")
        super.awakeFromNib()
        self.gg_configureFlowLayout()
    }
    
    /*
    /*
    + (Class)layoutAttributesClass
    {
        return [MessagesCollectionViewLayoutAttributes class];
    }
    */

    override class func invalidationContextClass() -> AnyClass {
        return MessagesCollectionViewFlowLayoutInvalidationContext.self
    }

    // pragma mark - Setters
    /*
    - (void)setBubbleSizeCalculator:(id<MessagesBubbleSizeCalculating>)bubbleSizeCalculator
    {
        NSParameterAssert(bubbleSizeCalculator != nil);
        _bubbleSizeCalculator = bubbleSizeCalculator;
    }
    */
/*
- (id<MessagesBubbleSizeCalculating>)bubbleSizeCalculator
{
    if (_bubbleSizeCalculator == nil) {
        _bubbleSizeCalculator = [MessagesBubblesSizeCalculator new];
    }

    return _bubbleSizeCalculator;
}
*/

    // pragma mark - Notifications

    func gg_didReceiveApplicationMemoryWarningNotification(notification: NSNotification) {
        self.gg_resetLayout()
    }

    func gg_didReceiveDeviceOrientationDidChangeNotification(notification: NSNotification) {
        self.gg_resetLayout()
        self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
    }

    // pragma mark - Collection view flow layout

    func invalidateLayoutWithContext(context: MessagesCollectionViewFlowLayoutInvalidationContext) {
        if (context.invalidateDataSourceCounts) {
            context.invalidateFlowLayoutAttributes = true
            context.invalidateFlowLayoutDelegateMetrics = true
        }
        
        if (context.invalidateFlowLayoutAttributes
            || context.invalidateFlowLayoutDelegateMetrics) {
            self.gg_resetDynamicAnimator()
        }
        
        if (context.invalidateFlowLayoutMessagesCache) {
            self.gg_resetLayout()
        }
        
        super.invalidateLayoutWithContext(context)
    }

    override func prepareLayout() {
        super.prepareLayout()
        
        if (self.springinessEnabled) {
            //  pad rect to avoid flickering
            let padding: CGFloat = -100.0
            let visibleRect: CGRect = CGRectInset((self.collectionView?.bounds)!, padding, padding)
            
            let visibleItems: NSArray = super.layoutAttributesForElementsInRect(visibleRect)
            let visibleItemsIndexPaths: NSSet = NSSet.setWithArray(visibleItems.valueForKey(NSStringFromSelector(Selector(indexPath))))
            
            self.gg_removeNoLongerVisibleBehaviorsFromVisibleItemsIndexPaths(visibleItemsIndexPaths)
            
            self.gg_addNewlyVisibleBehaviorsFromVisibleItems(visibleItems)
        }
    }

    func layoutAttributesForElementsInRect(rect: CGRect) -> NSArray {
        var attributesInRect: NSArray = super.layoutAttributesForElementsInRect(rect)
    
        if (self.springinessEnabled) {
            let attributesInRectCopy: NSMutableArray = attributesInRect.mutableCopy()
            let dynamicAttributes: NSArray = self.dynamicAnimator?.itemsInRect(rect)
            
            //  avoid duplicate attributes
            //  use dynamic animator attribute item instead of regular item, if it exists
            for (eachItem in attributesInRect) {
                for (eachDynamicItem in dynamicAttributes) {
                    if (eachItem.indexPath.isEqual(eachDynamicItem.indexPath)
                        && eachItem.representedElementCategory == eachDynamicItem.representedElementCategory) {
                        attributesInRectCopy.removeObject(eachItem)
                        attributesInRectCopy.addObject(eachDynamicItem)
                        continue
                    }
                }
            }
            
            attributesInRect = attributesInRectCopy
        }
        
        for index in 0...attributesInRect.count {
            if (attributesInRect[index].representedElementCategory == UICollectionElementCategory.Cell) {
                self.gg_configureMessageCellLayoutAttributes(attributesInRect[index])
            } else {
                attributesInRect[index].zIndex = -1;
            }
        }
        
        return attributesInRect
    }

    func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let customAttributes: MessagesCollectionViewLayoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath) as MessagesCollectionViewLayoutAttributes
        
        if (customAttributes.representedElementCategory == UICollectionElementCategory.Cell) {
            self.gg_configureMessageCellLayoutAttributes(customAttributes)
        }
        
        return customAttributes
    }

    func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if (self.springinessEnabled) {
            let scrollView: UIScrollView = self.collectionView
            let delta: CGFloat = newBounds.origin.y - scrollView.bounds.origin.y
            
            self.latestDelta = delta
            
            let touchLocation: CGPoint = self.collectionView.panGestureRecognizer(locationInView: self.collectionView)
            
            self.dynamicAnimator.behaviors.enumerateObjectsUsingBlock({ springBehaviour, index, stop) in
                self.gg_adjustSpringBehavior(springBehaviour, forTouchLocation:touchLocation)
                self.dynamicAnimator.updateItemUsingCurrentState(springBehaviour.items.firstObject())
            })
        }
        
        let oldBounds: CGRect = self.collectionView.bounds
        if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
            return true
        }
        
        return false
    }

    func prepareForCollectionViewUpdates(updateItems: NSArray) {
        super.prepareForCollectionViewUpdates(updateItems)
        
        updateItems.enumerateObjectsUsingBlock({updateItem, index, stop) in
            if (updateItem.updateAction == UICollectionUpdateAction.Insert) {
                
                if (self.springinessEnabled && self.dynamicAnimator.layoutAttributesForCellAtIndexPath(updateItem.indexPathAfterUpdate)) {
                    stop = false
                }
                
                let collectionViewHeight: CGFloat = CGRectGetHeight(self.collectionView.bounds)
                
                let attributes: MessagesCollectionViewLayoutAttributes = MessagesCollectionViewLayoutAttributes.layoutAttributesForCellWithIndexPath(updateItem.indexPathAfterUpdate)
                
                if (attributes.representedElementCategory == UICollectionElementCategory.Cell) {
                    self.gg_configureMessageCellLayoutAttributes(attributes)
                }
                
                attributes.frame = CGRectMake(0.0,
                    collectionViewHeight + CGRectGetHeight(attributes.frame),
                    CGRectGetWidth(attributes.frame),
                    CGRectGetHeight(attributes.frame));
                
                if (self.springinessEnabled) {
                    let springBehavior: UIAttachmentBehavior = self.gg_springBehaviorWithLayoutAttributesItem(attributes)
                    self.dynamicAnimator.addBehavior(springBehaviour)
                }
            }
        })
    }

    // pragma mark - Invalidation utilities

    func gg_resetLayout() {
        // self.bubbleSizeCalculator.prepareForResettingLayout(self)
        self.gg_resetDynamicAnimator()
    }

    func gg_resetDynamicAnimator() {
        if (self.springinessEnabled) {
            self.dynamicAnimator!.removeAllBehaviors()
            self.visibleIndexPaths.removeAllObjects()
        }
    }

    // pragma mark - Message cell layout utilities

    func messageBubbleSizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let messageItem: Message = self.collectionView?.dataSource.collectionView(
            self.collectionView,
            messageDataForItemAtIndexPath:indexPath)

        return self.bubbleSizeCalculator.messageBubbleSizeForMessageData(
            messageItem,
            atIndexPath:indexPath,
            withLayout:self)
    }

    func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let messageBubbleSize: CGSize = self.messageBubbleSizeForItemAtIndexPath(indexPath)
        let attributes: MessagesCollectionViewLayoutAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) as! MessagesCollectionViewLayoutAttributes
        
        var finalHeight: CGFloat = messageBubbleSize.height
        finalHeight += attributes.cellTopLabelHeight
        finalHeight += attributes.messageBubbleTopLabelHeight
        finalHeight += attributes.cellBottomLabelHeight
        
        return CGSizeMake(self.itemWidth, ceil(finalHeight));
    }

    func gg_configureMessageCellLayoutAttributes(layoutAttributes: MessagesCollectionViewLayoutAttributes) {
        let indexPath: NSIndexPath = layoutAttributes.indexPath
        
        let messageBubbleSize: CGSize = self.messageBubbleSizeForItemAtIndexPath(indexPath)
        layoutAttributes.messageBubbleContainerViewWidth = messageBubbleSize.width
        layoutAttributes.textViewFrameInsets = self.messageBubbleTextViewFrameInsets
        layoutAttributes.textViewTextContainerInsets = self.messageBubbleTextViewTextContainerInsets
        layoutAttributes.messageBubbleFont = self.messageBubbleFont
        layoutAttributes.incomingAvatarViewSize = self.incomingAvatarViewSize
        layoutAttributes.outgoingAvatarViewSize = self.outgoingAvatarViewSize
        layoutAttributes.cellTopLabelHeight = self.collectionView.delegate.collectionView(
            self.collectionView,
            layout:self,
            heightForCellTopLabelAtIndexPath:indexPath)
        
        layoutAttributes.messageBubbleTopLabelHeight = self.collectionView.delegate.collectionView(
            self.collectionView,
            layout: self,
            heightForMessageBubbleTopLabelAtIndexPath:indexPath)
        
        layoutAttributes.cellBottomLabelHeight = self.collectionView.delegate.collectionView(
            self.collectionView,
            layout:self,
            heightForCellBottomLabelAtIndexPath:indexPath)
    }

    // pragma mark - Spring behavior utilities

    func gg_springBehaviorWithLayoutAttributesItem(item: UICollectionViewLayoutAttributes) -> UIAttachmentBehavior? {
        if (CGSizeEqualToSize(item.frame.size, CGSizeZero)) {
            // adding a spring behavior with zero size will fail in in -prepareForCollectionViewUpdates:
            return nil
        }
        
        let springBehavior: UIAttachmentBehavior = UIAttachmentBehavior(
            item:item,
            attachedToAnchor: item.center)
        springBehavior.length = 1.0
        springBehavior.damping = 1.0
        springBehavior.frequency = 1.0
        return springBehavior
    }

    func gg_addNewlyVisibleBehaviorsFromVisibleItems(visibleItems: NSArray) {
        //  a "newly visible" item is in `visibleItems` but not in `self.visibleIndexPaths`
        let indexSet: NSIndexSet = visibleItems.indexesOfObjectsPassingTest({item: UICollectionViewLayoutAttributes, index, stop) in
            return !self.visibleIndexPaths.containsObject(item.indexPath)
        })
        
        let newlyVisibleItems: NSArray = visibleItems.objectsAtIndexes(indexSet)
        
        let touchLocation: CGPoint = self.collectionView.panGestureRecognizer.locationInViews(self.collectionView)
        
        newlyVisibleItems.enumerateObjectsUsingBlock({ item: UICollectionViewLayoutAttributes, index, stop) in
            let springBehaviour: UIAttachmentBehavior = self.gg_springBehaviorWithLayoutAttributesItem(item)
            self.gg_adjustSpringBehavior(springBehaviour, forTouchLocation:touchLocation)
            self.dynamicAnimator.addBehavior(springBehaviour)
            self.visibleIndexPaths.addObject(item.indexPath)
        })
    }

    func gg_removeNoLongerVisibleBehaviorsFromVisibleItemsIndexPaths(visibleItemsIndexPaths: NSSet) {
        let behaviors: NSArray = self.dynamicAnimator.behaviors
        
        let indexSet: NSIndexSet = behaviors.indexesOfObjectsPassingTest({springBehaviour: UIAttachmentBehavior, index, stop) in
            let layoutAttributes: UICollectionViewLayoutAttributes = springBehaviour.items.first! as UICollectionViewLayoutAttributes
            return !visibleItemsIndexPaths.containsObject(layoutAttributes.indexPath)
        })
        
        let behaviorsToRemove: NSArray = self.dynamicAnimator.behaviors.objectsAtIndexes(indexSet)
        
        behaviorsToRemove.enumerateObjectsUsingBlock({ springBehaviour: UIAttachmentBehavior, index, stop) {
            let layoutAttributes: UICollectionViewLayoutAttributes = springBehaviour.items.first! as! UICollectionViewLayoutAttributes
            self.dynamicAnimator.removeBehavior(springBehaviour)
            self.visibleIndexPaths.removeObject(layoutAttributes.indexPath)
        })
    }

    func gg_adjustSpringBehavior(springBehavior: UIAttachmentBehavior, forTouchLocation touchLocation: CGPoint) {
        let item: UICollectionViewLayoutAttributes = springBehavior.items.first! as! UICollectionViewLayoutAttributes
        var center: CGPoint = item.center
        
        //  if touch is not (0,0) -- adjust item center "in flight"
        if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
            let distanceFromTouch: CGFloat = fabs(touchLocation.y - springBehavior.anchorPoint.y)
            let scrollResistance: CGFloat = distanceFromTouch / self.springResistanceFactor
            
            if (self.latestDelta < 0.0) {
                center.y += max(self.latestDelta, self.latestDelta * scrollResistance)
            }
            else {
                center.y += min(self.latestDelta, self.latestDelta * scrollResistance)
            }
            item.center = center
        }
    }
    */
}
