//
//  MessageAvatarImage.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageAvatarImage {
  
    var avatarImage: UIImage?
    var avatarHighlightedImage: UIImage?
    var avatarPlaceholderImage: UIImage
   
    init(avatarImage: UIImage?,
        highlightedImage: UIImage?,
        placeholderImage: UIImage) {
        
        self.avatarImage = avatarImage
        self.avatarHighlightedImage = highlightedImage
        self.avatarPlaceholderImage = placeholderImage
    }
    class func avatarWithImage(image: UIImage) -> MessageAvatarImage {
       return MessageAvatarImage(avatarImage: image, highlightedImage: image, placeholderImage: image)
    }
    
    class func avatarImageWithPlaceholder(placeholder: UIImage) -> MessageAvatarImage {
       return MessageAvatarImage(avatarImage: nil, highlightedImage: nil, placeholderImage: placeholder)
    }
}