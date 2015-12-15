//
//  XMPPvCardManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/29/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

//
//  XMPPvCardManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/27/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public class XMPPvCardManager: NSObject {
	
	// MARK: Singleton
	
	class var sharedInstance : XMPPvCardManager {
		struct XMPPvCardManagerSingleton {
			static let instance = XMPPvCardManager()
		}
		return XMPPvCardManagerSingleton.instance
	}
    
    func updateDisplayName(name: String) {
        if let vCardTemp = XMPPManager.sharedInstance.vCardTempModule.myvCardTemp {
            vCardTemp.nickname = name
            XMPPManager.sharedInstance.vCardTempModule.updateMyvCardTemp(vCardTemp)
        } else {
            let vCardXML = DDXMLElement(name: "vCard", xmlns: "vcard-temp:x:update")
            let newvCardTemp: XMPPvCardTemp = XMPPvCardTemp(fromElement: vCardXML)
            newvCardTemp.nickname = name
            // newvCardTemp.name = name
            // newvCardTemp.familyName = name
            XMPPManager.sharedInstance.vCardTempModule.updateMyvCardTemp(newvCardTemp)
        }
    }
    
    func updateAvatarImage(avatar: UIImage) {
        let imageData: NSData = UIImagePNGRepresentation(avatar)!
        // let queue: dispatch_queue_t = dispatch_queue_create("queue", DISPATCH_QUEUE_PRIORITY_DEFAULT)
        let queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue) {
            let vCardTempModule = XMPPManager.sharedInstance.vCardTempModule
            let myVcardTemp = vCardTempModule.myvCardTemp
            myVcardTemp.photo = imageData
            vCardTempModule.updateMyvCardTemp(myVcardTemp)
        }
    }
    
    func fetchvCardForJID(jid: XMPPJID) {
        // let jid = XMPPJID.jidWithString(jidStr)
        
        XMPPManager.sharedInstance.vCardTempModule.fetchvCardTempForJID(jid)
    }
    
    func getvCardForJID(jid: XMPPJID) -> XMPPvCardTemp {
        let vcard = XMPPManager.sharedInstance.vCardStorage.vCardTempForJID(jid,
            xmppStream: XMPPManager.sharedInstance.stream)
        
        return vcard
    }
}

extension XMPPManager {

    func xmppvCardTempModuleDidUpdateMyvCard(vCardTempModule: XMPPvCardTempModule!) {
        print("didUpdateMyvCard")
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, failedToUpdateMyvCard error: DDXMLElement!) {
        print("failedToUpdateMyvCard: \(error)")
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, didReceivevCardTemp vCardTemp: XMPPvCardTemp!, forJID jid: XMPPJID!) {
        print("didReceivevCardTemp")
        let vcard = self.vCardStorage.vCardTempForJID(jid,
            xmppStream: self.stream)
        
        if let user = self.rosterStorage.userForJID(
            jid,
            xmppStream: self.stream,
            managedObjectContext: XMPPRosterManager.sharedInstance.managedObjectContext_roster()) {
            user.nickname = vcard.nickname
        }
        
        print(vcard.description)
    }
}