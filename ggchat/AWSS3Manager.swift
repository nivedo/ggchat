//
//  AWSS3Manager.swift
//  ggchat
//
//  Created by Gary Chang on 12/3/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

class AWSS3Manager {
    
    class var sharedInstance: AWSS3Manager {
        struct Singleton {
            static let instance = AWSS3Manager()
        }
        return Singleton.instance
    }
    
    class func start() {
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: GGSetting.awsCognitoRegionType,
            identityPoolId: GGSetting.awsCognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(
            region: GGSetting.awsServiceRegionType,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    }
    
}