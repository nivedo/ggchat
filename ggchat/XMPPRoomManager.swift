//
//  XMPPRoomManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/13/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class ChatRoom {
    var xmppRoom: XMPPRoom
    var inviteList: [String]
    var user: RosterUser
    
    init(xmppRoom: XMPPRoom, inviteList: [String], json: [String: AnyObject]) {
        self.xmppRoom = xmppRoom
        self.inviteList = inviteList
        self.user = RosterUser(groupProfile: json)
    }
}

protocol XMPPRoomManagerDelegate : NSObjectProtocol {
    func didJoinRoom(room: ChatRoom)
}

class XMPPRoomManager: NSObject,
    XMPPRoomDelegate,
    XMPPMUCDelegate {
    
    class var sharedInstance : XMPPRoomManager {
        struct XMPPRoomManagerSingleton {
            static let instance = XMPPRoomManager()
        }
        return XMPPRoomManagerSingleton.instance
    }
   
    var delegate: XMPPRoomManagerDelegate?
    var rooms = [String: ChatRoom]()
    var muc: XMPPMUC?
  
    func setupMUC() {
        self.muc = XMPPMUC(dispatchQueue: dispatch_get_main_queue())
        self.muc!.activate(XMPPManager.sharedInstance.stream)
        self.muc!.addDelegate(self, delegateQueue: dispatch_get_main_queue())
    }
    
    func joinRoom(roomID: String, invitees: [String], json: [String: AnyObject]) {
        if !XMPPManager.sharedInstance.isConnected() {
            return
        }
        if let chatRoom = self.rooms[roomID] {
            let xmppRoom = chatRoom.xmppRoom
            if !xmppRoom.isJoined {
                xmppRoom.joinRoomUsingNickname(UserAPI.sharedInstance.displayName,
                    history: nil,
                    password: nil)
                chatRoom.inviteList = invitees
            }
        } else {
            let roomJID = XMPPJID.jidWithString(roomID)
            let roomMemory = XMPPRoomMemoryStorage()
            let xmppRoom = XMPPRoom(
                roomStorage: roomMemory,
                jid:roomJID,
                dispatchQueue: dispatch_get_main_queue())
            self.rooms[roomID] = ChatRoom(xmppRoom: xmppRoom, inviteList: invitees, json: json)
            xmppRoom.activate(XMPPManager.sharedInstance.stream)
            xmppRoom.addDelegate(self, delegateQueue: dispatch_get_main_queue())
            xmppRoom.joinRoomUsingNickname(UserAPI.sharedInstance.jidBareStr,
                history: nil,
                password: nil)
        }
    }
    
    var welcome: String {
        get {
            return "\(UserAPI.sharedInstance.displayName) invited you to group chat!"
        }
    }
    
    func inviteUsersToRoom(roomID: String, usersJID: [String]) {
        if !XMPPManager.sharedInstance.isConnected() {
            return
        }
        if let xmppRoom = self.rooms[roomID]?.xmppRoom {
            for jid in usersJID {
                xmppRoom.inviteUser(XMPPJID.jidWithString(jid), withMessage: self.welcome)
            }
        }
    }
    
    func xmppRoomDidCreate(sender: XMPPRoom) {
        print("xmppRoomDidCreate")
    }
    
    func xmppRoomDidJoin(sender: XMPPRoom) {
        print("xmppRoomDidJoin")
        let roomJID = UserAPI.stripResourceFromJID(sender.myRoomJID.bare())
        if let chatRoom = self.rooms[roomJID] {
            self.delegate?.didJoinRoom(chatRoom)
            for jid in chatRoom.inviteList {
                chatRoom.xmppRoom.inviteUser(XMPPJID.jidWithString(jid), withMessage: self.welcome)
            }
        }
    }
   
    func xmppMUC(sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {
        print("MUC didReceiveInvitation")
        let x = message.elementForName("x", xmlns:XMPPMUCUserNamespace)
        if let _ = x.elementForName("invite") {
            let conferenceRoomJID = message.attributeForName("from").stringValue
            // self.joinMultiUserChatRoom(conferenceRoomJID)
        }
    }
}
