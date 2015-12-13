//
//  TrieNode.swift
//  ggchat
//
//  Created by Gary Chang on 12/13/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public class TrieNode {
    
    var key: String!
    var children: Array<TrieNode>
    var isFinal: Bool
    var level: Int
    var terminalKeys = [String]()
    
    init() {
        self.children = Array<TrieNode>()
        self.isFinal = false
        self.level = 0
    }
    
    
}

