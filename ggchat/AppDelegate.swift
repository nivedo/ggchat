//
//  AppDelegate.swift
//  ggchat
//
//  Created by Gary Chang on 11/8/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import TSMessages

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default
        // UIApplication.sharedApplication().statusBarHidden = false
        
        UserAPI.sharedInstance.loadCoreData()
        
        print("application::didFinishLaunchingWithOptions")
        let logLevel = XMPP_LOG_FLAG_SEND | XMPP_LOG_FLAG_TRACE | XMPP_LOG_FLAG_VERBOSE
        DDLog.addLogger(DDASLLogger.sharedInstance(), withLogLevel: logLevel)
        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLogLevel: logLevel)
        
        XMPPManager.start()
        AWSS3Manager.start()
   
        // Register remote notifications with APNS
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        } else {
            let type: UIRemoteNotificationType = UIRemoteNotificationType(rawValue: (UIRemoteNotificationType.Alert.rawValue | UIRemoteNotificationType.Badge.rawValue | UIRemoteNotificationType.Sound.rawValue))
            application.registerForRemoteNotificationTypes(type)
        }
        
        // Check launch options
        if let options = launchOptions {
            if let payload = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                // Launched from remote notification
                print("Launch from remote notification: \(payload)")
                
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                UIApplication.sharedApplication().cancelAllLocalNotifications()
            } else if let local = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                print("Launch from local notification: \(local)")
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                UIApplication.sharedApplication().cancelAllLocalNotifications()
            }
        }
        
        // Crash reporting
        Fabric.with([Crashlytics.self])
        
        // Load assets
        GGWiki.sharedInstance
        
        // Load root view
        self.initializeRootView(true)
        
        TSMessageView.appearance().alpha = 0.8
        // TSMessageView.appearance().backgroundColor = UIColor.blackColor()
        
        return true
    }
    
    func initializeRootView(animated: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginIdentifier = "LoginViewController"
      
        var isAuthenticated = UserAPI.sharedInstance.canAuth
        if ConnectionManager.isConnectedToNetwork() {
            isAuthenticated = UserAPI.sharedInstance.authenticate({(success: Bool) -> Void in
                if success {
                    print("Connecting with \(UserAPI.sharedInstance.jid!):\(UserAPI.sharedInstance.jpassword!)")
                    XMPPManager.sharedInstance.connectWithJID(
                        jid: UserAPI.sharedInstance.jid!,
                        password: UserAPI.sharedInstance.jpassword!,
                        connectCompletionHandler: self.xmppConnectCallback,
                        authenticateCompletionHandler: self.xmppAuthenticateCallback)
                } else {
                    self.segueToLoginViewController()
                }
            })
        }
        
        let identifier = isAuthenticated ? "TabBarController" : loginIdentifier
        let viewController = storyboard.instantiateViewControllerWithIdentifier(identifier)
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController = viewController
    }
    
    func segueToLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginIdentifier = "LoginViewController"
        dispatch_async(dispatch_get_main_queue()) {
            let loginController = storyboard.instantiateViewControllerWithIdentifier(loginIdentifier)
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController = loginController
        }
    }
    
    func xmppConnectCallback(stream: XMPPStream, error: String?) {
        if (error != nil) {
            self.segueToLoginViewController()
        }
    }
    
    func xmppAuthenticateCallback(stream: XMPPStream, error: String?) {
        if (error != nil) {
            self.segueToLoginViewController()
        }
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("didRegisterUserNotficationSettings")
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // print("Remote notification token: \(deviceToken)")
        var token = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        token = token.stringByReplacingOccurrencesOfString(" ", withString: "")
        UserAPI.sharedInstance.pushToken = token
    }
   
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Failed to get token: \(error)")
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().cancelAllLocalNotifications()

        /*
        XMPPManager.sharedInstance.connectWithJID(
            jid: nil,
            password: nil,
            connectCompletionHandler: nil,
            authenticateCompletionHandler: nil)
        */
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        XMPPManager.stop()
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("applicationDidReceiveRemoteNotification: \(UIApplication.sharedApplication().applicationState))")
        print(userInfo)
    }
   
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("applicationDidReceiveLocalNotification: \(UIApplication.sharedApplication().applicationState))")
    }
}

