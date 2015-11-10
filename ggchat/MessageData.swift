//
//  MessageData.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

protocol MessageData {
    
    var senderId: String { get }
    var senderDisplayName: String { get}
    var date: NSDate { get }
    var isMediaMessage: Bool { get }
    var text: String? { get }
    var media: MessageMediaData? { get }
    
    func messageHash() -> UInt
}