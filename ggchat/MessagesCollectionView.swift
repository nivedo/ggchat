//
//  MessagesCollectionView.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class MessagesCollectionView: UICollectionView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    var messagesDataSource: MessagesViewController?
    var messagesCollectionViewLayout: MessagesCollectionViewFlowLayout?
}
