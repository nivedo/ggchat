//
//  XMPPPresenceManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/27/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

// MARK: Protocol
public protocol XMPPPresenceManagerDelegate {
	func onPresenceDidReceivePresence()
}

public class XMPPPresenceManager: NSObject {
	var delegate: XMPPPresenceManagerDelegate?
	
	// MARK: Singleton
	
	class var sharedInstance : XMPPPresenceManager {
		struct XMPPPresenceManagerSingleton {
			static let instance = XMPPPresenceManager()
		}
		return XMPPPresenceManagerSingleton.instance
	}
	
	// MARK: Functions
	
	class func goOnline() {
		let presence = XMPPPresence()
		let domain = XMPPManager.sharedInstance.stream.myJID.domain
	
        /*
		if domain == "gmail.com" || domain == "gtalk.com" || domain == "talk.google.com" {
			let priority: DDXMLElement = DDXMLElement(name: "priority", stringValue: "24")
			presence.addChild(priority)
		}
        */
		
		XMPPManager.sharedInstance.stream.sendElement(presence)
	}
	
	class func goOffline() {
		var _ = XMPPPresence(type: "unavailable")
	}
}

extension XMPPManager {
	
    func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        let presenceType = presence.type()
        let presenceFromJID = presence.fromStr()
        
        if !UserAPI.sharedInstance.isOutgoingJID(presenceFromJID) {
            print("******************************************")
            print("didReceivePresence from \(presenceFromJID)")
            if (presenceType == "available") {
                print("\(presenceFromJID) is \(presenceType)")
            } else if (presenceType == "unavailable") {
                print("\(presenceFromJID) is \(presenceType)")
            } else if (presenceType == "subscribe") {
                print("\(presenceFromJID) wants to subscribe")
                /*
                var accept: Bool = true
                if (accept) {
                    self.roster.acceptPresenceSubscriptionRequestFrom(
                        presence.from(),
                        andAddToRoster: true)
                } else {
                    self.roster.rejectPresenceSubscriptionRequestFrom(
                        presence.from())
                }
                */
            }
        }
    }
}