//
//  String+Messages.swift
//  ggchat
//
//  Created by Gary Chang on 11/18/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

extension String {
    func gg_stringByTrimingWhitespace() -> String {
        return self.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}