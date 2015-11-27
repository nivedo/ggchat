//
//  GGModelData.swift
//  ggchat
//
//  Created by Gary _chang on 11/10/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class Demo {
    static var displayName_chang = "Gary Chang"
    static var displayName_cook = "Tim Cook"
    static var displayName_jobs = "Jobs"
    static var displayName_woz = "Steve Wozniak"
    
    static var id_chang = "gchang@chat.blub.io"
    static var id_cook = "468-768355-23123"
    static var id_jobs = "707-8956784-57"
    static var id_woz = "309-41802-93823"
    
    static var avatarSize: CGFloat = 30.0
}

class GGModelData {
    var messages = [Message]()
    var chats = [Chat]()
    var avatars = [String:MessageAvatarImage]()
    var users = [String:String]()
    var contacts = [Contact]()
   
    class var sharedInstance: GGModelData {
        struct Singleton {
            static let instance = GGModelData()
        }
        return Singleton.instance
    }
    
    init() {
        self.loadMessages()
        self.loadChats()
        self.loadAvatars()
        self.loadUsers()
        self.loadContacts()
    }
    
    func loadContacts() {
        self.contacts = [
            Contact(
                id: Demo.id_chang,
                displayName: Demo.displayName_chang),
            Contact(
                id: Demo.id_cook,
                displayName: Demo.displayName_cook),
            Contact(
                id: Demo.id_woz,
                displayName: Demo.displayName_woz),
            Contact(
                id: Demo.id_jobs,
                displayName: Demo.displayName_jobs),
        ]
    }
    
    func loadMessages() {
        self.messages = [
            Message(
                senderId: Demo.id_chang,
                senderDisplayName: Demo.displayName_chang,
                date: NSDate.distantPast(),
                text: "Welcome to GG Chat, a chat app for gamers!"),
            Message(
                senderId: Demo.id_cook,
                senderDisplayName: Demo.displayName_cook,
                date: NSDate.distantPast(),
                text: "GG Chat is awesome!"),
            Message(
                senderId: Demo.id_chang,
                senderDisplayName: Demo.displayName_chang,
                date: NSDate.distantPast(),
                text: "That's right!"),
            Message(
                senderId: Demo.id_woz,
                senderDisplayName: Demo.displayName_woz,
                date: NSDate.distantPast(),
                text: "This looks way better than LINE or WeChat or iMessage, I wish Apple built this app."),
            Message(
                senderId: Demo.id_jobs,
                senderDisplayName: Demo.displayName_jobs,
                date: NSDate.distantPast(),
                text: "This is the world's most beautiful chat app in the world."),
        ]
    }
    
    func loadChats() {
        self.chats = [
            Chat(
                chatId: "Gary Chang",
                chatDisplayName: "Gary Chang",
                recentMessage: "This is the most recent message.",
                recentUpdateTime: "April 25"),
            Chat(
                chatId: "Jay Ni",
                chatDisplayName: "Jay Ni",
                recentMessage: "Yo!",
                recentUpdateTime: "Nov 7"),
            Chat(
                chatId: "Group Chat",
                chatDisplayName: "Group Chat",
                recentMessage: "Hi everyone!!!",
                recentUpdateTime: "Dec 1"),
        ]
    }
    
    func loadAvatars() {
        self.avatars = [
            Demo.id_chang : MessageAvatarImageFactory.avatarImageWithUserInitials("GC",
                backgroundColor: UIColor(white: 0.85, alpha: 1.0),
                textColor: UIColor(white: 0.60, alpha: 1.0),
                font: UIFont.systemFontOfSize(14.0),
                diameter: Demo.avatarSize),
            Demo.id_cook : MessageAvatarImageFactory.avatarImageWithImage(
                UIImage(named: "demo_avatar_cook")!,
                diameter: Demo.avatarSize),
            Demo.id_jobs : MessageAvatarImageFactory.avatarImageWithImage(
                UIImage(named: "demo_avatar_jobs")!,
                diameter: Demo.avatarSize),
            Demo.id_woz : MessageAvatarImageFactory.avatarImageWithImage(
                UIImage(named: "demo_avatar_woz")!,
                diameter: Demo.avatarSize),
        ]
    }
    
    func loadUsers() {
        self.users = [
            Demo.id_chang : Demo.displayName_chang,
            Demo.id_cook : Demo.displayName_cook,
            Demo.id_jobs : Demo.displayName_jobs,
            Demo.id_woz : Demo.displayName_woz,
        ]
    }
    
    func addPhotoMediaMessage() {
        /*
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
        JSQMessage *photoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                       displayName:kJSQDemoAvatarDisplayNameSquires
                                                             media:photoItem];
        [self.messages addObject:photoMessage];
        */
    }

    func addLocationMediaMessageCompletion(completion: LocationMediaItemCompletionBlock) {
        /*
        CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
        
        JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
        [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
        
        JSQMessage *locationMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                          displayName:kJSQDemoAvatarDisplayNameSquires
                                                                media:locationItem];
        [self.messages addObject:locationMessage];
        */
    }

    func addVideoMediaMessage() {
        /*
        // don't have a real video, just pretending
        NSURL *videoURL = [NSURL URLWithString:@"file://"];
        
        JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
        JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                       displayName:kJSQDemoAvatarDisplayNameSquires
                                                             media:videoItem];
        [self.messages addObject:videoMessage];
        */
    }


}