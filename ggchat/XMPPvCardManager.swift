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
    
    func updateDisplayName(givenName: String, familyName: String) {
        // let vCardTemp: XMPPvCardTemp = self.vCardTempModule.myvCardTemp
        let vCardXML = DDXMLElement(name: "vCard", xmlns: "vcard-temp")
        let newvCardTemp: XMPPvCardTemp = XMPPvCardTemp(fromElement: vCardXML)
        newvCardTemp.givenName = givenName
        newvCardTemp.familyName = familyName
        XMPPManager.sharedInstance.vCardTempModule.updateMyvCardTemp(newvCardTemp)
    }
}

extension XMPPManager {

    func xmppvCardTempModuleDidUpdateMyvCard(vCardTempModule: XMPPvCardTempModule) {
        
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule, failedToUpdateMyvCard error:DDXMLElement) {
        
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, didReceivevCardTemp vCardTemp: XMPPvCardTemp!, forJID jid: XMPPJID!) {
        print("didReceivevCardTemp")
        let vcard = XMPPManager.sharedInstance.vCardStorage.vCardTempForJID(jid,
            xmppStream: XMPPManager.sharedInstance.stream)
        print(vcard.description)
    }
}