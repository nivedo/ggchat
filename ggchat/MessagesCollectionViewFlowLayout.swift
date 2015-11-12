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
   
    var collectionView: MessagesCollectionView?
    
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
            return CGRectGetWidth(self.collectionView!.frame) - self.sectionInset.left - self.sectionInset.right;
        }
    }
  
    var latestDelta: CGFloat
    var messageBubbleTextViewFrameInsets: UIEdgeInsets
    var springResistanceFactor: CGFloat

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
    
    /*
    override init() {
        super.init()
        self.gg_configureFlowLayout()
    }
    */

    override func awakeFromNib() {
        super.awakeFromNib()
        self.gg_configureFlowLayout()
    }
    
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
            let visibleRect: CGRect = CGRectInset(self.collectionView.bounds, padding, padding)
            
            NSArray *visibleItems = [super layoutAttributesForElementsInRect:visibleRect];
            NSSet *visibleItemsIndexPaths = [NSSet setWithArray:[visibleItems valueForKey:NSStringFromSelector(@selector(indexPath))]];
            
            [self gg_removeNoLongerVisibleBehaviorsFromVisibleItemsIndexPaths:visibleItemsIndexPaths];
            
            [self gg_addNewlyVisibleBehaviorsFromVisibleItems:visibleItems];
        }
    }

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributesInRect = [super layoutAttributesForElementsInRect:rect];
    
    if (self.springinessEnabled) {
        NSMutableArray *attributesInRectCopy = [attributesInRect mutableCopy];
        NSArray *dynamicAttributes = [self.dynamicAnimator itemsInRect:rect];
        
        //  avoid duplicate attributes
        //  use dynamic animator attribute item instead of regular item, if it exists
        for (UICollectionViewLayoutAttributes *eachItem in attributesInRect) {
            
            for (UICollectionViewLayoutAttributes *eachDynamicItem in dynamicAttributes) {
                if ([eachItem.indexPath isEqual:eachDynamicItem.indexPath]
                    && eachItem.representedElementCategory == eachDynamicItem.representedElementCategory) {
                    
                    [attributesInRectCopy removeObject:eachItem];
                    [attributesInRectCopy addObject:eachDynamicItem];
                    continue;
                }
            }
        }
        
        attributesInRect = attributesInRectCopy;
    }
    
    [attributesInRect enumerateObjectsUsingBlock:^(MessagesCollectionViewLayoutAttributes *attributesItem, NSUInteger idx, BOOL *stop) {
        if (attributesItem.representedElementCategory == UICollectionElementCategoryCell) {
            [self gg_configureMessageCellLayoutAttributes:attributesItem];
        }
        else {
            attributesItem.zIndex = -1;
        }
    }];
    
    return attributesInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MessagesCollectionViewLayoutAttributes *customAttributes = (MessagesCollectionViewLayoutAttributes *)[super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (customAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        [self gg_configureMessageCellLayoutAttributes:customAttributes];
    }
    
    return customAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    if (self.springinessEnabled) {
        UIScrollView *scrollView = self.collectionView;
        CGFloat delta = newBounds.origin.y - scrollView.bounds.origin.y;
        
        self.latestDelta = delta;
        
        CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
        
        [self.dynamicAnimator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger idx, BOOL *stop) {
            [self gg_adjustSpringBehavior:springBehaviour forTouchLocation:touchLocation];
            [self.dynamicAnimator updateItemUsingCurrentState:[springBehaviour.items firstObject]];
        }];
    }
    
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    
    return NO;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [super prepareForCollectionViewUpdates:updateItems];
    
    [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem *updateItem, NSUInteger index, BOOL *stop) {
        if (updateItem.updateAction == UICollectionUpdateActionInsert) {
            
            if (self.springinessEnabled && [self.dynamicAnimator layoutAttributesForCellAtIndexPath:updateItem.indexPathAfterUpdate]) {
                *stop = YES;
            }
            
            CGFloat collectionViewHeight = CGRectGetHeight(self.collectionView.bounds);
            
            MessagesCollectionViewLayoutAttributes *attributes = [MessagesCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:updateItem.indexPathAfterUpdate];
            
            if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
                [self gg_configureMessageCellLayoutAttributes:attributes];
            }
            
            attributes.frame = CGRectMake(0.0f,
                                          collectionViewHeight + CGRectGetHeight(attributes.frame),
                                          CGRectGetWidth(attributes.frame),
                                          CGRectGetHeight(attributes.frame));
            
            if (self.springinessEnabled) {
                UIAttachmentBehavior *springBehaviour = [self gg_springBehaviorWithLayoutAttributesItem:attributes];
                [self.dynamicAnimator addBehavior:springBehaviour];
            }
        }
    }];
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

- (CGSize)messageBubbleSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<MessageData> messageItem = [self.collectionView.dataSource collectionView:self.collectionView
                                                      messageDataForItemAtIndexPath:indexPath];

    return [self.bubbleSizeCalculator messageBubbleSizeForMessageData:messageItem
                                                          atIndexPath:indexPath
                                                           withLayout:self];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize messageBubbleSize = [self messageBubbleSizeForItemAtIndexPath:indexPath];
    MessagesCollectionViewLayoutAttributes *attributes = (MessagesCollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:indexPath];
    
    CGFloat finalHeight = messageBubbleSize.height;
    finalHeight += attributes.cellTopLabelHeight;
    finalHeight += attributes.messageBubbleTopLabelHeight;
    finalHeight += attributes.cellBottomLabelHeight;
    
    return CGSizeMake(self.itemWidth, ceilf(finalHeight));
}

- (void)gg_configureMessageCellLayoutAttributes:(MessagesCollectionViewLayoutAttributes *)layoutAttributes
{
    NSIndexPath *indexPath = layoutAttributes.indexPath;
    
    CGSize messageBubbleSize = [self messageBubbleSizeForItemAtIndexPath:indexPath];
    
    layoutAttributes.messageBubbleContainerViewWidth = messageBubbleSize.width;
    
    layoutAttributes.textViewFrameInsets = self.messageBubbleTextViewFrameInsets;
    
    layoutAttributes.textViewTextContainerInsets = self.messageBubbleTextViewTextContainerInsets;
    
    layoutAttributes.messageBubbleFont = self.messageBubbleFont;
    
    layoutAttributes.incomingAvatarViewSize = self.incomingAvatarViewSize;
    
    layoutAttributes.outgoingAvatarViewSize = self.outgoingAvatarViewSize;
    
    layoutAttributes.cellTopLabelHeight = [self.collectionView.delegate collectionView:self.collectionView
                                                                                layout:self
                                                      heightForCellTopLabelAtIndexPath:indexPath];
    
    layoutAttributes.messageBubbleTopLabelHeight = [self.collectionView.delegate collectionView:self.collectionView
                                                                                         layout:self
                                                      heightForMessageBubbleTopLabelAtIndexPath:indexPath];
    
    layoutAttributes.cellBottomLabelHeight = [self.collectionView.delegate collectionView:self.collectionView
                                                                                   layout:self
                                                      heightForCellBottomLabelAtIndexPath:indexPath];
}

#pragma mark - Spring behavior utilities

- (UIAttachmentBehavior *)gg_springBehaviorWithLayoutAttributesItem:(UICollectionViewLayoutAttributes *)item
{
    if (CGSizeEqualToSize(item.frame.size, CGSizeZero)) {
        // adding a spring behavior with zero size will fail in in -prepareForCollectionViewUpdates:
        return nil;
    }
    
    UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:item.center];
    springBehavior.length = 1.0f;
    springBehavior.damping = 1.0f;
    springBehavior.frequency = 1.0f;
    return springBehavior;
}

- (void)gg_addNewlyVisibleBehaviorsFromVisibleItems:(NSArray *)visibleItems
{
    //  a "newly visible" item is in `visibleItems` but not in `self.visibleIndexPaths`
    NSIndexSet *indexSet = [visibleItems indexesOfObjectsPassingTest:^BOOL(UICollectionViewLayoutAttributes *item, NSUInteger index, BOOL *stop) {
        return ![self.visibleIndexPaths containsObject:item.indexPath];
    }];
    
    NSArray *newlyVisibleItems = [visibleItems objectsAtIndexes:indexSet];
    
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    [newlyVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *item, NSUInteger index, BOOL *stop) {
        UIAttachmentBehavior *springBehaviour = [self gg_springBehaviorWithLayoutAttributesItem:item];
        [self gg_adjustSpringBehavior:springBehaviour forTouchLocation:touchLocation];
        [self.dynamicAnimator addBehavior:springBehaviour];
        [self.visibleIndexPaths addObject:item.indexPath];
    }];
}

- (void)gg_removeNoLongerVisibleBehaviorsFromVisibleItemsIndexPaths:(NSSet *)visibleItemsIndexPaths
{
    NSArray *behaviors = self.dynamicAnimator.behaviors;
    
    NSIndexSet *indexSet = [behaviors indexesOfObjectsPassingTest:^BOOL(UIAttachmentBehavior *springBehaviour, NSUInteger index, BOOL *stop) {
        UICollectionViewLayoutAttributes *layoutAttributes = (UICollectionViewLayoutAttributes *)[springBehaviour.items firstObject];
        return ![visibleItemsIndexPaths containsObject:layoutAttributes.indexPath];
    }];
    
    NSArray *behaviorsToRemove = [self.dynamicAnimator.behaviors objectsAtIndexes:indexSet];
    
    [behaviorsToRemove enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger index, BOOL *stop) {
        UICollectionViewLayoutAttributes *layoutAttributes = (UICollectionViewLayoutAttributes *)[springBehaviour.items firstObject];
        [self.dynamicAnimator removeBehavior:springBehaviour];
        [self.visibleIndexPaths removeObject:layoutAttributes.indexPath];
    }];
}

- (void)gg_adjustSpringBehavior:(UIAttachmentBehavior *)springBehavior forTouchLocation:(CGPoint)touchLocation
{
    UICollectionViewLayoutAttributes *item = (UICollectionViewLayoutAttributes *)[springBehavior.items firstObject];
    CGPoint center = item.center;
    
    //  if touch is not (0,0) -- adjust item center "in flight"
    if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
        CGFloat distanceFromTouch = fabs(touchLocation.y - springBehavior.anchorPoint.y);
        CGFloat scrollResistance = distanceFromTouch / self.springResistanceFactor;
        
        if (self.latestDelta < 0.0f) {
            center.y += MAX(self.latestDelta, self.latestDelta * scrollResistance);
        }
        else {
            center.y += MIN(self.latestDelta, self.latestDelta * scrollResistance);
        }
        item.center = center;
    }
}
*/
}
