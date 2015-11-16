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

    var messageDelegate: MessageViewController { return self.delegate as! MessageViewController }
    var messageDataSource: MessageViewController { return self.dataSource as! MessageViewController }
    var messageCollectionViewLayout: MessagesCollectionViewFlowLayout { return self.collectionViewLayout as! MessagesCollectionViewFlowLayout }
}
