//
//  MediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MediaItem: NSObject, NSCoding, NSCopying, MessageMediaData {

    var cachedPlaceholderView: UIView?
    var appliesMediaViewMaskAsOutgoing: Bool = true {
        didSet {
            self.cachedPlaceholderView = nil
        }
    }

    // pragma mark - Initialization

    required override init() {
        super.init()
        self.initWithMaskAsOutgoing(true)
    }
    
    func initWithMaskAsOutgoing(maskAsOutgoing: Bool) {
        self.appliesMediaViewMaskAsOutgoing = true
        self.cachedPlaceholderView = nil
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("didReceiveMemoryWarningNotification:"),
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil)
    }

    func clearCachedMediaViews() {
        self.cachedPlaceholderView = nil
    }

    // pragma mark - Notifications

    func didReceiveMemoryWarningNotification(notification: NSNotification) {
        self.clearCachedMediaViews()
    }

    // pragma mark - MessageMediaData protocol

    func mediaView() -> UIView? {
        assert(false, "Error! required method not implemented in subclass. Need to implement")
        return nil
    }

    func mediaViewDisplaySize() -> CGSize {
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return CGSizeMake(315.0, 225.0)
        }
        
        return CGSizeMake(210.0, 150.0)
    }

    func mediaPlaceholderView() -> UIView? {
        if (self.cachedPlaceholderView == nil) {
            let size: CGSize = self.mediaViewDisplaySize()
            let view: UIView = MessageMediaPlaceholderView.viewWithActivityIndicator()
            view.frame = CGRectMake(0.0, 0.0, size.width, size.height)
            MessageMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(view,
                isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedPlaceholderView = view
        }

        return self.cachedPlaceholderView
    }

    func mediaHash() -> Int {
        return self.hash
    }

    // pragma mark - NSObject
    override func isEqual(_ object: AnyObject?) -> Bool {
        if (self === object) {
            return true
        }
        
        if (!object!.isKindOfClass(self.dynamicType)) {
            return false
        }
        
        let item: MediaItem = object as! MediaItem
        
        return self.appliesMediaViewMaskAsOutgoing == item.appliesMediaViewMaskAsOutgoing
    }

    override var hash: Int {
        return NSNumber(bool: self.appliesMediaViewMaskAsOutgoing).hash
    }

    override var description: String {
        return "<\(self.dynamicType): appliesMediaViewMaskAsOutgoing=\(self.appliesMediaViewMaskAsOutgoing)>"
    }
    
    // pragma mark - NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init()
        self.initWithMaskAsOutgoing(true)
        self.appliesMediaViewMaskAsOutgoing = aDecoder.decodeBoolForKey(NSStringFromSelector(Selector("appliesMediaViewMaskAsOutgoing")))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeBool(self.appliesMediaViewMaskAsOutgoing,
            forKey: NSStringFromSelector(Selector("appliesMediaViewMaskAsOutgoing")))
    }

    // pragma mark - NSCopying

    func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = self.dynamicType.init()
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }

}
