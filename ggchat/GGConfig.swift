//
//  GGConfig.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

struct GGConfig {
    static let backgroundColor = UIColor.whiteColor()
    static let cellTopLabelTextColor = UIColor.lightGrayColor()
    static let cellBottomLabelTextColor = UIColor.lightGrayColor()
    static let bubbleTopLabelTextColor = UIColor.lightGrayColor()
    static let incomingBubbleColor = UIColor.gg_messageBubbleGreenColor()
    static let incomingTextColor = UIColor.whiteColor()
    static let outgoingBubbleColor = UIColor.gg_messageBubbleLightGrayColor()
    static let outgoingTextColor = UIColor.whiteColor()
    static let springinessEnabled = false // true
}

struct GGConfig_Dark {
    static let backgroundColor = UIColor.darkGrayColor()
    static let cellTopLabelTextColor = UIColor.whiteColor()
    static let cellBottomLabelTextColor = UIColor.whiteColor()
    static let bubbleTopLabelTextColor = UIColor.whiteColor()
    static let incomingBubbleColor = UIColor.whiteColor()
    static let incomingTextColor = UIColor.darkGrayColor()
    static let outgoingBubbleColor = UIColor.gg_messageBubbleGreenColor()
    static let outgoingTextColor = UIColor.whiteColor()
    static let springinessEnabled = true
}