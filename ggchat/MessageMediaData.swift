//
//  MessageMediaData.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol MessageMediaDelegate {
    func redrawMessageMedia()
}

protocol MessageMediaData {
    
    func mediaView() -> UIView?
    func mediaViewDisplaySize() -> CGSize
    func mediaPlaceholderView() -> UIView?
    func mediaHash() -> Int
    func setNeedsDisplay()
    
}