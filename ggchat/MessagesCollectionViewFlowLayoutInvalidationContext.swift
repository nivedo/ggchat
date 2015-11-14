//
//  MessagesCollectionViewFlowLayoutInvalidationContext.swift
//  ggchat
//
//  Created by Gary Chang on 11/12/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionViewFlowLayoutInvalidationContext: UICollectionViewFlowLayoutInvalidationContext {
   
    /*
    var invalidateFlowLayoutDelegateMetrics: Bool
    var invalidateFlowLayoutAttributes: Bool
    */
    var invalidateFlowLayoutMessagesCache: Bool
        
    // pragma mark - Initialization
    override init() {
        self.invalidateFlowLayoutMessagesCache = false
        super.init()
        self.invalidateFlowLayoutDelegateMetrics = false
        self.invalidateFlowLayoutAttributes = false
    }
    
    class func context() -> MessagesCollectionViewFlowLayoutInvalidationContext {
        let context: MessagesCollectionViewFlowLayoutInvalidationContext = MessagesCollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutDelegateMetrics = true
        context.invalidateFlowLayoutAttributes = true
        return context
    }
    
    // pragma mark - NSObject
    
    override var description: String {
        get {
            return "<\(self.dynamicType): invalidateFlowLayoutDelegateMetrics=\(self.invalidateFlowLayoutDelegateMetrics), invalidateFlowLayoutAttributes=\(self.invalidateFlowLayoutAttributes), invalidateDataSourceCounts=\(invalidateDataSourceCounts), invalidateFlowLayoutMessagesCache=\(self.invalidateFlowLayoutMessagesCache)>"
        }
    }
}
