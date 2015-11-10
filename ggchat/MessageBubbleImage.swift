//
//  MessageBubbleImage.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageBubbleImage {
    
    var messageBubbleImage: UIImage
    var messageBubbleHighlightedImage: UIImage
    
    init(image: UIImage, highlightedImage: UIImage) {
        self.messageBubbleImage = image
        self.messageBubbleHighlightedImage = highlightedImage
    }
}