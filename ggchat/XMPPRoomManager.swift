//
//  XMPPRoomManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/13/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class XMPPRoomManager: NSObject {
    
    class var sharedInstance : XMPPRoomManager {
        struct XMPPRoomManagerSingleton {
            static let instance = XMPPRoomManager()
        }
        return XMPPRoomManagerSingleton.instance
    }
    
    var roomMemory = XMPPRoomMemoryStorage()
    
    
}