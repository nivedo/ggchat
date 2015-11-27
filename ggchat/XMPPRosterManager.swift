//
//  XMPPRosterManager.swift
//  ggchat
//
//  Created by Gary Chang on 11/27/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

//
//  XMPPRosterManager.swift
//  XMPPManager
//
//  Created by Paul on 26/02/2015.
//  Copyright (c) 2015 ProcessOne. All rights reserved.
//

import Foundation

public protocol XMPPRosterManagerDelegate {
	func onRosterContentChanged(controller: NSFetchedResultsController)
}

public class XMPPRosterManager: NSObject, NSFetchedResultsControllerDelegate {
	public var delegate: XMPPRosterManagerDelegate?
	public var fetchedResultsControllerVar: NSFetchedResultsController?
	
	// MARK: Singleton
	
	public class var sharedInstance : XMPPRosterManager {
		struct XMPPRosterManagerSingleton {
			static let instance = XMPPRosterManager()
		}
		return XMPPRosterManagerSingleton.instance
	}
	
	public class var buddyList: NSFetchedResultsController {
		get {
			if sharedInstance.fetchedResultsControllerVar != nil {
				return sharedInstance.fetchedResultsControllerVar!
			}
			return sharedInstance.fetchedResultsController()!
		}
	}
	
	// MARK: Core Data
	
	func managedObjectContext_roster() -> NSManagedObjectContext {
		return XMPPManager.sharedInstance.rosterStorage.mainThreadManagedObjectContext
	}
	
	private func managedObjectContext_capabilities() -> NSManagedObjectContext {
		return XMPPManager.sharedInstance.rosterStorage.mainThreadManagedObjectContext
	}
	
	public func fetchedResultsController() -> NSFetchedResultsController? {
		if fetchedResultsControllerVar == nil {
			let moc = XMPPRosterManager.sharedInstance.managedObjectContext_roster() as NSManagedObjectContext?
			let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: moc!)
			let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
			let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
			
			let sortDescriptors = [sd1, sd2]
			let fetchRequest = NSFetchRequest()
			
			fetchRequest.entity = entity
			fetchRequest.sortDescriptors = sortDescriptors
			fetchRequest.fetchBatchSize = 10
			
			fetchedResultsControllerVar = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc!, sectionNameKeyPath: "sectionNum", cacheName: nil)
			fetchedResultsControllerVar?.delegate = self
			
			do {
				try fetchedResultsControllerVar!.performFetch()
			} catch let error as NSError {
				print("Error: \(error.localizedDescription)")
				abort()
			}
			//  if fetchedResultsControllerVar?.performFetch() == nil {
			//Handle fetch error
			//}
		}
		
		return fetchedResultsControllerVar!
	}
	
	public class func userFromRosterAtIndexPath(indexPath indexPath: NSIndexPath) -> XMPPUserCoreDataStorageObject {
		return sharedInstance.fetchedResultsController()!.objectAtIndexPath(indexPath) as! XMPPUserCoreDataStorageObject
	}
	
	public class func userFromRosterForJID(jid jid: String) -> XMPPUserCoreDataStorageObject? {
		let userJID = XMPPJID.jidWithString(jid)
	
		if let user = XMPPManager.sharedInstance.rosterStorage.userForJID(
            userJID,
            xmppStream: XMPPManager.sharedInstance.stream,
            managedObjectContext: sharedInstance.managedObjectContext_roster()) {
			return user
		} else {
			return nil
		}
	}
	
	public class func removeUserFromRosterAtIndexPath(indexPath indexPath: NSIndexPath) {
		let user = userFromRosterAtIndexPath(indexPath: indexPath)
		sharedInstance.fetchedResultsControllerVar?.managedObjectContext.deleteObject(user)
	}
	
	public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("controllerDidChangeContent")
		delegate?.onRosterContentChanged(controller)
	}
}

extension XMPPRosterManager: XMPPRosterDelegate {
	
	public func xmppRoster(sender: XMPPRoster, didReceiveBuddyRequest presence:XMPPPresence) {
		//was let user
		_ = XMPPManager.sharedInstance.rosterStorage.userForJID(
            presence.from(),
            xmppStream: XMPPManager.sharedInstance.stream,
            managedObjectContext: managedObjectContext_roster())
	}
	
	public func xmppRosterDidEndPopulating(sender: XMPPRoster?) {
		let jidList = XMPPManager.sharedInstance.rosterStorage.jidsForXMPPStream(
            XMPPManager.sharedInstance.stream)
		print("List=\(jidList)")
	}
}

extension XMPPRosterManager: XMPPStreamDelegate {
	
	public func xmppStream(sender: XMPPStream, didReceiveIQ ip: XMPPIQ) -> Bool {
		if let msg = ip.attributeForName("from") {
			if msg.stringValue() == "conference.chat.blub.io"  {
				
			}
		}
		return false
	}
}