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
        // let vCardTemp: XMPPvCardTemp = self.vCardTempModule.myvCardTemp
        let vCardXML = DDXMLElement(name: "vCard", xmlns: "vcard-temp")
        let newvCardTemp: XMPPvCardTemp = XMPPvCardTemp(fromElement: vCardXML)
        newvCardTemp.nickname = name
        XMPPManager.sharedInstance.vCardTempModule.updateMyvCardTemp(newvCardTemp)
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
        print(vcard.description)
    }
}