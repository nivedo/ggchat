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
        self.jid = UserAPI.stripResourceFromJID(jid)
        self.xmppRoom = xmppRoom
        self.inviteList = inviteList
        self.user = RosterUser(
            jid: self.jid,
            groupName: groupName,
            avatar: avatar)
        UserAPI.sharedInstance.addRosterUser(self.user)
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
    
    /*
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
    */
    
    func xmppRoomDidCreate(sender: XMPPRoom) {
        print("xmppRoomDidCreate \(sender.myRoomJID.bare())")
    }
    
    func xmppRoomDidJoin(sender: XMPPRoom) {
        UserAPI.sharedInstance.syncGroups({(success: Bool, errorMsg: String?) -> Void in
            print("sync groups \(success)")
        })
        
        let roomJID = UserAPI.stripResourceFromJID(sender.myRoomJID.bare())
        print("xmppRoomDidJoin \(roomJID)")
        if let chatRoom = self.rooms[roomJID] {
            self.delegate?.didJoinRoom(chatRoom)
            for jid in chatRoom.inviteList {
                chatRoom.xmppRoom.inviteUser(XMPPJID.jidWithString(jid), withMessage: self.welcome)
            }
            if chatRoom.inviteList.count > 0 {
                let now = NSDate()
                let id = "\(roomJID):\(now.description)"
                let msg = Message(
                    id: id,
                    fromId: roomJID,
                    senderId: UserAPI.sharedInstance.jidBareStr,
                    isOutgoing: true,
                    date: now,
                    attributedText: NSAttributedString(string: self.welcome))
                UserAPI.sharedInstance.newMessage(roomJID, date: now, message: msg)
            }
        }
    }
   
    func xmppMUC(sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {
        let conferenceJID = roomJID.bare()
        print("MUC didReceiveInvitation: \(conferenceJID)")
        print(message)
        let type = message.attributeStringValueForName("type")
        if type != "error" {
            let x = message.elementForName("x", xmlns:XMPPMUCUserNamespace)
            if let _ = x.elementForName("invite") {
                let from = message.attributeStringValueForName("from")
                print("from \(from)")
                self.joinOrCreateRoom(conferenceJID, invitees: [], groupName: "", avatar: "")
            }
        }
    }
}
