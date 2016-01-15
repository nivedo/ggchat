//
//  ConnectionManager.swift
//  ggchat
//
//  Created by Gary Chang on 1/14/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation
import SystemConfiguration
import TSMessages

class ConnectionManager {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }

    class func checkConnection(viewController: UIViewController) {
        if !self.isConnectedToNetwork() {
            TSMessage.showNotificationInViewController(viewController,
                title: "Network error",
                subtitle: "Couldn't connect to server. Please check network connection",
                type: TSMessageNotificationType.Error)
        } else {
            if UserAPI.sharedInstance.hasAuth {
                XMPPManager.refresh()
            }
        }
    }
}