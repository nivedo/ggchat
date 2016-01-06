//
//  UserAPICoreData.swift
//  ggchat
//
//  Created by Gary Chang on 1/6/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation
import CoreData

class UserAPICoreData {
    
    class var sharedInstance: UserAPICoreData {
        struct Singleton {
            static let instance = UserAPICoreData()
        }
        return Singleton.instance
    }
    
    init() {
        // let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        // let managedContext = appDelegate.managedObjectContext!
    }
    
    func addUser(rosterUser: RosterUser) -> User? {
        let entity =  NSEntityDescription.entityForName("User",
            inManagedObjectContext: self.managedObjectContext)
        
        let user = User(entity: entity!,
            insertIntoManagedObjectContext: self.managedObjectContext)
        user.set(rosterUser)
        
        do {
            try self.managedObjectContext.save()
            return user
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func syncUser(rosterUser: RosterUser) {
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "jid = %@", rosterUser.jidBare)
       
        do {
            let fetchResults = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            if let users = fetchResults as? [User] {
                if users.count != 0 {
                    let user = users[0]
                    if user.update(rosterUser) {
                        print("[CORE DATA] Update \(rosterUser.displayName)")
                        do {
                            try self.managedObjectContext.save()
                        } catch let error as NSError {
                            print("Could not save \(error), \(error.userInfo)")
                        }
                    } else {
                        // print("[CORE DATA] Pass \(rosterUser.displayName)")
                    }
                } else {
                    print("[CORE DATA] Add \(rosterUser.displayName)")
                    self.addUser(rosterUser)
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func fetchAllUsers() -> [User]? {
        let fetchRequest = NSFetchRequest(entityName: "User")
        
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            return results as? [User]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.plymouthsoftware.core_data" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("UserAPIModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("ggchat.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}