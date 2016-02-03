//
//  XMPPRoomManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/13/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class ChatRoom {
    var jid: String
    var xmppRoom: XMPPRoom
    var inviteList: [String]
    var user: RosterUser
    
    init(jid: String, xmppRoom: XMPPRoom, inviteList: [String], groupName: String, avatar: String) {
        self.jid = jid
        self.xmppRoom = xmppRoom
        self.inviteList = inviteList
        self.user = RosterUser(
            jid: jid,
            groupName: groupName,
            avatar: avatar)
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
    
    func joinOrCreateRoom(roomIDStr: String, invitees: [String], groupName: String, avatar: String) {
        if !XMPPManager.sharedInstance.isConnected() {
            return
        }
        let roomID = roomIDStr.lowercaseString
        if let chatRoom = self.rooms[roomID] {
            let xmppRoom = chatRoom.xmppRoom
            if !xmppRoom.isJoined {
                xmppRoom.joinRoomUsingNickname(UserAPI.sharedInstance.displayName,
                    history: nil,
                    password: nil)
                chatRoom.inviteList = invitees
            }
        } else {
            print("joinRoomUserNickname, jid: \(roomID), uuid: \(UserAPI.sharedInstance.uuidStr)")
            let roomJID = XMPPJID.jidWithString(roomID)
            let roomMemory = XMPPRoomMemoryStorage()
            let xmppRoom = XMPPRoom(
                roomStorage: roomMemory,
                jid:roomJID,
                dispatchQueue: dispatch_get_main_queue())
            self.rooms[roomID] = ChatRoom(jid: roomID, xmppRoom: xmppRoom, inviteList: invitees, groupName: groupName, avatar: avatar)
            xmppRoom.activate(XMPPManager.sharedInstance.stream)
            xmppRoom.addDelegate(self, delegateQueue: dispatch_get_main_queue())
            xmppRoom.joinRoomUsingNickname(UserAPI.sharedInstance.uuidStr,
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
        print("xmppRoomDidCreate \(sender.myRoomJID.bare())")
    }
    
    func xmppRoomDidJoin(sender: XMPPRoom) {
        let roomJID = UserAPI.stripResourceFromJID(sender.myRoomJID.bare())
        print("xmppRoomDidJoin \(roomJID)")
        if let chatRoom = self.rooms[roomJID] {
            self.delegate?.didJoinRoom(chatRoom)
            for jid in chatRoom.inviteList {
                chatRoom.xmppRoom.inviteUser(XMPPJID.jidWithString(jid), withMessage: self.welcome)
            }
        }
    }
   
    func xmppMUC(sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {
        print("MUC didReceiveInvitation: \(roomJID.bare())")
        print(message)
        let type = message.attributeStringValueForName("type")
        if type != "error" {
            let x = message.elementForName("x", xmlns:XMPPMUCUserNamespace)
            if let _ = x.elementForName("invite") {
                let from = message.attributeForName("from").stringValue
                print("from \(from)")
                // self.joinMultiUserChatRoom(conferenceRoomJID)
            }
        }
    }
}
