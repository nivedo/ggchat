//
//  GGConfig.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

struct GGConfig_iMessage {
    static let backgroundColor = UIColor.whiteColor()
    static let loadButtonColorNormal = UIColor.lightGrayColor()
    static let cellTopLabelTextColor = UIColor.lightGrayColor()
    static let cellBottomLabelTextColor = UIColor.lightGrayColor()
    static let bubbleTopLabelTextColor = UIColor.lightGrayColor()
    static let incomingBubbleColor = UIColor.gg_messageBubbleGreenColor()
    static let incomingTextColor = UIColor.whiteColor()
    static let outgoingBubbleColor = UIColor.gg_messageBubbleLightGrayColor()
    static let outgoingTextColor = UIColor.whiteColor()
    static let springinessEnabled = false
}

struct GGConfig_Old {
    static let backgroundColor = UIColor.grayColor()
    static let loadButtonColorNormal = UIColor.lightGrayColor()
    static let cellTopLabelTextColor = UIColor.whiteColor()
    static let cellBottomLabelTextColor = UIColor.whiteColor()
    static let bubbleTopLabelTextColor = UIColor.whiteColor()
    static let incomingBubbleColor = UIColor.whiteColor()
    static let incomingTextColor = UIColor.darkGrayColor()
    static let outgoingBubbleColor = UIColor.gg_messageBubbleGreenColor()
    static let outgoingTextColor = UIColor.whiteColor()
    static let springinessEnabled = false
    static let avatarSize: CGFloat = 30.0
}

struct GGConfig {
    static let backgroundColor = UIColor(red:0.93, green:0.94, blue:0.95, alpha:1.0)
    static let loadButtonColorNormal = UIColor.lightGrayColor()
    static let cellTopLabelTextColor = UIColor(red:0.73, green:0.73, blue:0.73, alpha:1.0)
    static let cellBottomLabelTextColor = UIColor(red:0.73, green:0.73, blue:0.73, alpha:1.0)
    static let bubbleTopLabelTextColor = UIColor(red:0.73, green:0.73, blue:0.73, alpha:1.0)
    static let incomingBubbleColor = UIColor.whiteColor()
    static let incomingTextColor = UIColor.darkGrayColor()
    static let outgoingBubbleColor = UIColor(red:0.81, green:0.94, blue:0.62, alpha:1.0)
    static let outgoingTextColor = UIColor.darkGrayColor()
    static let springinessEnabled = false
    static let avatarSize: CGFloat = 30.0
    static let badgeSize: CGFloat = 16.0
    static let messageBubbleFont: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    static let messageComposerFont: UIFont = UIFont.systemFontOfSize(16.0)
    static let messageTimeFont: UIFont = UIFont.systemFontOfSize(12.0)
    static let messageTopFont: UIFont = UIFont.systemFontOfSize(12.0)
    static let messageBottomFont: UIFont = UIFont.systemFontOfSize(11.0)
    static let paginationLimit: Int = 30
}

struct GGConfig_Dark {
    static let backgroundColor = UIColor.darkGrayColor()
    static let loadButtonColorNormal = UIColor.lightGrayColor()
    static let cellTopLabelTextColor = UIColor.whiteColor()
    static let cellBottomLabelTextColor = UIColor.whiteColor()
    static let bubbleTopLabelTextColor = UIColor.whiteColor()
    static let incomingBubbleColor = UIColor.whiteColor()
    static let incomingTextColor = UIColor.darkGrayColor()
    static let outgoingBubbleColor = UIColor.gg_messageBubbleGreenColor()
    static let outgoingTextColor = UIColor.whiteColor()
    static let springinessEnabled = false
}

struct GGKey {
    static let email = "email"
    static let password = "password"
    
    static let userApiAuthToken = "user.api.authToken"
    static let userApiPushToken = "user.api.pushToken"
    static let userApiJID = "user.api.jid"
    static let userApiJabberdPassword = "user.api.jpassword"
    static let userApiNickname = "user.api.nickname"
    static let userApiAvatarPath = "user.api.avatarPath"
    
    static let facebookId = "facebook.id"
    static let facebookToken = "facebook.token"
}

struct GGSetting {
    static let xmppDomain = "chat.blub.io"
    
    static let awsCognitoRegionType = AWSRegionType.APNortheast1
    static let awsServiceRegionType = AWSRegionType.APNortheast1
    static let awsCognitoIdentityPoolId = "ap-northeast-1:7fb7c28f-a7ff-491d-a02b-8a139014388d"
    static let awsS3BucketName = "ggchat-tokyo"
    static let awsS3AvatarsBucketName = "ggchat-avatars-tokyo"
    
    static let userApiHost = "45.55.192.24"
    static let userApiPort = "5000"
}