//
//  MessagesCollectionViewFlowLayout.swift
//  ggchat
//
//  Created by Gary Chang on 11/11/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    let kMessagesCollectionViewCellLabelHeightDefault: CGFloat = 154
    let kMessagesCollectionViewAvatarSizeDefault: CGFloat = 32.0
    
    var messageCollectionView: MessagesCollectionView!
    
    var bubbleSizeCalculator: MessageBubbleSizeCalculator = MessageBubbleSizeCalculator()
    lazy var dynamicAnimator: UIDynamicAnimator = self.initDynamicAnimator()
    
    func initDynamicAnimator() -> UIDynamicAnimator {
        return UIDynamicAnimator(collectionViewLayout:self)
    }
    

    // pragma mark - Getters
    
    var visibleIndexPaths: NSMutableSet = NSMutableSet()
    
    var itemWidth : CGFloat {
        get {
            return CGRectGetWidth(self.messageCollectionView.frame) - self.sectionInset.left - self.sectionInset.right
        }
    }
  
    var latestDelta: CGFloat = 0.0
    var messageBubbleTextViewFrameInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 6.0)
    var springResistanceFactor: CGFloat = 1000

    var springinessEnabled: Bool = false {
        willSet {
            /*
            if (self.springinessEnabled == newValue) {
                return
            }
            */
            
            if (!newValue) {
                // self.dynamicAnimator!.removeAllBehaviors()
                self.visibleIndexPaths.removeAllObjects()
            }
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }

    var messageBubbleFont: UIFont! {
        didSet {
            if (self.messageBubbleFont.isEqual(oldValue)) {
                return
            }
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }

    var messageBubbleLeftRightMargin: CGFloat! {
        willSet {
            assert(newValue >= 0.0)
            self.messageBubbleLeftRightMargin = ceil(newValue)
        }
        didSet {
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }

    var messageBubbleTextViewTextContainerInsets: UIEdgeInsets! {
        didSet {
            /*
            if (UIEdgeInsetsEqualToEdgeInsets(self.messageBubbleTextViewTextContainerInsets, oldValue)) {
                return
            }
            */
            
            self.invalidateLayoutWithContext (MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }
    
    var incomingAvatarViewSize: CGSize! {
        didSet {
            /*
            if (CGSizeEqualToSize(self.incomingAvatarViewSize, oldValue)) {
                return
            }
            */
            
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }
    
    var outgoingAvatarViewSize: CGSize! {
        didSet {
            /*
            if (CGSizeEqualToSize(self.outgoingAvatarViewSize, oldValue)) {
                return
            }
            */
            
            self.invalidateLayoutWithContext(MessagesCollectionViewFlowLayoutInvalidationContext.context())
        }
    }

    func gg_configureFlowLayout() {
        print("gg_configureFlowLayout()")
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
    
    override class func layoutAttributesClass() -> AnyClass {
        return MessagesCollectionViewLayoutAttributes.self
    }

    /*
    override class func invalidationContextClass() -> AnyClass {
        return MessagesCollectionViewFlowLayoutInvalidationContext.self
    }

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
    */
    /*
    override func prepareLayout() {
        super.prepareLayout()
        
        if (self.springinessEnabled) {
            //  pad rect to avoid flickering
            let padding: CGFloat = -100.0
            let visibleRect: CGRect = CGRectInset((self.messageCollectionView?.bounds)!, padding, padding)
            /*
            let visibleItems: NSArray = super.layoutAttributesForElementsInRect(visibleRect)!
            let visibleItemsIndexPaths: NSSet = NSSet.setWithArray(visibleItems.valueForKey(NSStringFromSelector(Selector("indexPath:"))) as! [AnyObject])
            // self.gg_removeNoLongerVisibleBehaviorsFromVisibleItemsIndexPaths(visibleItemsIndexPaths)
            
            // self.gg_addNewlyVisibleBehaviorsFromVisibleItems(visibleItems)
            */
        }
    }
    */
    
    override func layoutAttributesForElementsInRect(_ rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesInRect: [UICollectionViewLayoutAttributes] = super.layoutAttributesForElementsInRect(rect)!
        /*
        if (self.springinessEnabled) {
            var attributesInRectCopy = attributesInRect
            let dynamicAttributes: NSArray = self.dynamicAnimator.itemsInRect(rect)
            
            //  avoid duplicate attributes
            //  use dynamic animator attribute item instead of regular item, if it exists
            for (indexItem, eachItem) in attributesInRect.enumerate() {
                for (_, eachDynamicItem) in dynamicAttributes.enumerate() {
                    if (eachItem.indexPath.isEqual(eachDynamicItem.indexPath)
                        && eachItem.representedElementCategory == eachDynamicItem.representedElementCategory) {
                        attributesInRectCopy.removeAtIndex(indexItem)
                        attributesInRectCopy.insert(eachDynamicItem as! UICollectionViewLayoutAttributes, atIndex: indexItem)
                        continue
                    }
                }
            }
            
            attributesInRect = attributesInRectCopy
        }
        */
        /*
        for index in 0...attributesInRect.count {
            let attributesElem = attributesInRect[index] as! MessagesCollectionViewLayoutAttributes
            if (attributesInRect[index].representedElementCategory == UICollectionElementCategory.Cell) {
                self.gg_configureMessageCellLayoutAttributes(attributesElem)
            } else {
                attributesElem.zIndex = -1;
            }
        }
        */
        for (_, value) in attributesInRect.enumerate() {
            let attributesElem = value as! MessagesCollectionViewLayoutAttributes
            if (attributesElem.representedElementCategory == UICollectionElementCategory.Cell) {
                self.gg_configureMessageCellLayoutAttributes(attributesElem)
            } else {
                attributesElem.zIndex = -1;
            }
        }
        
        return attributesInRect
    }

    /*
    func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if (self.springinessEnabled) {
            let scrollView: UIScrollView = self.messageCollectionView
            let delta: CGFloat = newBounds.origin.y - scrollView.bounds.origin.y
            
            self.latestDelta = delta
            
            let touchLocation: CGPoint = self.messageCollectionView.panGestureRecognizer(locationInView: self.messageCollectionView)
            
            self.dynamicAnimator.behaviors.enumerateObjectsUsingBlock({ springBehaviour, index, stop) in
                self.gg_adjustSpringBehavior(springBehaviour, forTouchLocation:touchLocation)
                self.dynamicAnimator.updateItemUsingCurrentState(springBehaviour.items.firstObject())
            })
        }
        
        let oldBounds: CGRect = self.messageCollectionView.bounds
        if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
            return true
        }
        
        return false
    }
    */
    
    override func prepareForCollectionViewUpdates(_ updateItems: [UICollectionViewUpdateItem]) {
        super.prepareForCollectionViewUpdates(updateItems)
        
        // updateItems.enumerateObjectsUsingBlock({updateItem, index, stop) in
        for (_, value) in updateItems.enumerate() {
            let updateItem = value as UICollectionViewUpdateItem
            if (updateItem.updateAction == UICollectionUpdateAction.Insert) {
                
                /*
                if (self.springinessEnabled && self.dynamicAnimator.layoutAttributesForCellAtIndexPath(updateItem.indexPathAfterUpdate) != nil) {
                    stop = false
                }
                */
                
                let collectionViewHeight: CGFloat = CGRectGetHeight(self.messageCollectionView.bounds)
                
                let attributes: MessagesCollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: updateItem.indexPathAfterUpdate) as! MessagesCollectionViewLayoutAttributes
                
                if (attributes.representedElementCategory == UICollectionElementCategory.Cell) {
                    self.gg_configureMessageCellLayoutAttributes(attributes)
                }
                
                attributes.frame = CGRectMake(0.0,
                    collectionViewHeight + CGRectGetHeight(attributes.frame),
                    CGRectGetWidth(attributes.frame),
                    CGRectGetHeight(attributes.frame));
                
                /*
                if (self.springinessEnabled) {
                    let springBehavior: UIAttachmentBehavior = self.gg_springBehaviorWithLayoutAttributesItem(attributes)
                    self.dynamicAnimator.addBehavior(springBehaviour)
                }
                */
            }
        }
    }
   
    /*
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
    */
   
    /*
    func gg_addNewlyVisibleBehaviorsFromVisibleItems(visibleItems: NSArray) {
        //  a "newly visible" item is in `visibleItems` but not in `self.visibleIndexPaths`
        let indexSet: NSIndexSet = visibleItems.indexesOfObjectsPassingTest({item: UICollectionViewLayoutAttributes, index, stop) in
            return !self.visibleIndexPaths.containsObject(item.indexPath)
        })
        
        let newlyVisibleItems: NSArray = visibleItems.objectsAtIndexes(indexSet)
        
        let touchLocation: CGPoint = self.messageCollectionView.panGestureRecognizer.locationInViews(self.messageCollectionView)
        
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
    */
    
    /*
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
    func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        print("MVCFlowLayout::sizeForItemAtIndexPath()")
        let messageBubbleSize: CGSize = self.messageBubbleSizeForItemAtIndexPath(indexPath)
        let attributes: MessagesCollectionViewLayoutAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) as! MessagesCollectionViewLayoutAttributes
        var finalHeight: CGFloat = messageBubbleSize.height
        finalHeight += attributes.cellTopLabelHeight
        finalHeight += attributes.messageBubbleTopLabelHeight
        finalHeight += attributes.cellBottomLabelHeight
        
        return CGSizeMake(self.itemWidth, ceil(finalHeight));
        // return CGSizeMake(320.0, 154.0)
    }
    
    func messageBubbleSizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let messageItem: Message = self.messageCollectionView.messageDataSource.collectionView(
            self.messageCollectionView,
            messageDataForItemAtIndexPath: indexPath)

        return self.bubbleSizeCalculator.messageBubbleSizeForMessageData(
            messageItem,
            atIndexPath: indexPath,
            withLayout: self)
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let customAttributes: MessagesCollectionViewLayoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath) as! MessagesCollectionViewLayoutAttributes
        
        if (customAttributes.representedElementCategory == UICollectionElementCategory.Cell) {
            self.gg_configureMessageCellLayoutAttributes(customAttributes)
        }
        return customAttributes
    }
    
    func gg_configureMessageCellLayoutAttributes(layoutAttributes: MessagesCollectionViewLayoutAttributes) {
        print("gg_configureMessageCellLayoutAttributes()")
        let indexPath: NSIndexPath = layoutAttributes.indexPath
        
        let messageBubbleSize: CGSize = self.messageBubbleSizeForItemAtIndexPath(indexPath)
        layoutAttributes.messageBubbleContainerViewWidth = messageBubbleSize.width
        layoutAttributes.textViewFrameInsets = self.messageBubbleTextViewFrameInsets
        layoutAttributes.textViewTextContainerInsets = self.messageBubbleTextViewTextContainerInsets
        layoutAttributes.messageBubbleFont = self.messageBubbleFont
        layoutAttributes.incomingAvatarViewSize = self.incomingAvatarViewSize
        layoutAttributes.outgoingAvatarViewSize = self.outgoingAvatarViewSize
        layoutAttributes.cellTopLabelHeight = self.messageCollectionView.messageDelegate.collectionView(
            self.messageCollectionView,
            layout:self,
            heightForCellTopLabelAtIndexPath:indexPath)
        
        layoutAttributes.messageBubbleTopLabelHeight = self.messageCollectionView.messageDelegate.collectionView(
            self.messageCollectionView,
            layout: self,
            heightForMessageBubbleTopLabelAtIndexPath:indexPath)
        
        layoutAttributes.cellBottomLabelHeight = self.messageCollectionView.messageDelegate.collectionView(
            self.messageCollectionView,
            layout:self,
            heightForCellBottomLabelAtIndexPath:indexPath)
    }
}
