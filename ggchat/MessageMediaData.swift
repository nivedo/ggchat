//
//  MessageMediaData.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol MessageMediaData {
    
    var mediaView: UIView { get }
    var mediaViewDisplaySize: CGSize { get }
    var mediaPlaceholderView: UIView { get}
    var mediaHash: UInt { get }
    
}