//
//  GGMessageViewController.swift
//  ggchat
//
//  Created by Gary Chang on 11/16/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class GGMessageViewController: MessageViewController {

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
                print("GGMessageViewController::viewDidLoad()")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.senderId = Demo.id_chang
        self.senderDisplayName = Demo.displayName_chang
        self.messages = GGModelData.sharedInstance.messages
        self.showLoadEarlierMessagesHeader = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
