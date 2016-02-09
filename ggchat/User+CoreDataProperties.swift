//
//  User+CoreDataProperties.swift
//  ggchat
//
//  Created by Gary Chang on 2/9/16.
//  Copyright © 2016 Blub. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var avatar: String?
    @NSManaged var is_buddy: NSNumber?
    @NSManaged var jid: String?
    @NSManaged var nickname: String?
    @NSManaged var is_group: NSNumber?

}
