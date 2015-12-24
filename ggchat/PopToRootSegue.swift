//
//  PopToRootSegue.swift
//  ggchat
//
//  Created by Gary Chang on 12/24/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import UIKit

class PopToRootSegue: UIStoryboardSegue {

    override func perform() {
        let sourceViewController = self.sourceViewController 
        let destinationController = self.destinationViewController
        if let navigationController = sourceViewController.navigationController {
            // Pop to root view controller (not animated) before pushing
            navigationController.popToRootViewControllerAnimated(false)
            navigationController.pushViewController(destinationController, animated: true)
        }
    }
    
}
