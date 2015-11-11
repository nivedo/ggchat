//
//  DemoModelData.swift
//  ggchat
//
//  Created by Gary Chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class DemoModelData {
    static var kJSQDemoAvatarDisplayNameChang = "Gary Chang"
    static var kJSQDemoAvatarDisplayNameCook = "Tim Cook"
    static var kJSQDemoAvatarDisplayNameJobs = "Jobs"
    static var kJSQDemoAvatarDisplayNameWoz = "Steve Wozniak"
    
    static var kJSQDemoAvatarIdChang = "053496-4509-289"
    static var kJSQDemoAvatarIdCook = "468-768355-23123"
    static var kJSQDemoAvatarIdJobs = "707-8956784-57"
    static var kJSQDemoAvatarIdWoz = "309-41802-93823"
   
    var messages = [Message]()
    var avatars = [String:String]()
    var users = [String:String]()
    var outgoingBubbleImage: MessageBubbleImage
    var incomingBubbleImage: MessageBubbleImage
}