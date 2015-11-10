//
//  MessagesCollectionViewDataSource.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

protocol MessagesCollectionViewDataSource {
    
    var senderDisplayName: String { get }
    var senderId: String { get }
    
    func collectionView(collectionView: MessagesCollectionView,
        messageDataForItemAtIndexPath indexPath: NSIndexPath) -> MessageData
    
    func collectionView(collectionView: MessagesCollectionView,
        didDeleteMessageAtIndexPath indexPath: NSIndexPath)
    
}