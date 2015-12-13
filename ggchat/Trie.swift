//
//  Trie.swift
//  ggchat
//
//  Created by Gary Chang on 12/13/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation

public class Trie {
    
    private var root: TrieNode!
    
    init(){
        root = TrieNode()
    }
    
    //finds all words based on the prefix
    func findWord(keyword: String) -> Array<String>! {
        
        if (keyword.length == 0){
            return nil
        }
        
        var current: TrieNode = root
        var wordList: Array<String> = Array<String>()
        
        while (keyword.length != current.level) {
            var childToUse: TrieNode!
            let index = keyword.startIndex.advancedBy(current.level + 1)
            let searchKey: String = keyword.substringToIndex(index)
            
            // print("looking for prefix: \(searchKey) in \(current.children.count) child nodes")
            
            //iterate through any children
            for child in current.children {
                // print(child.key)
                if (child.key == searchKey) {
                    childToUse = child
                    current = childToUse
                    break
                }
            }
            
            if childToUse == nil {
                return nil
            }
        } //end while
        
        //retrieve the keyword and any decendants
        /*
        if ((current.key == keyword) && (current.isFinal)) {
            wordList.append(current.key)
        }
        */
        
        //include only children that are words
        /*
        for child in current.children {
            if (child.isFinal == true) {
                wordList.append(child.key)
            }
        }
        */
        self.getChildrenWord(current, wordList: &wordList)
        return wordList
    }
    
    func getChildrenWord(node: TrieNode, inout wordList: [String]) {
        if node.isFinal {
            wordList.append(node.key)
        }
        for child in node.children {
            self.getChildrenWord(child, wordList: &wordList)
        }
    }
    
    //builds a iterative tree of dictionary content
    func addWord(keyword: String) {
        
        if keyword.length == 0 {
            return
        }
        var current: TrieNode = root
        
        while(keyword.length != current.level) {
            
            var childToUse: TrieNode!
            let index = keyword.startIndex.advancedBy(current.level + 1)
            let searchKey: String = keyword.substringToIndex(index)
            
            //println("current has \(current.children.count) children..")
            
            //iterate through the node children
            for child in current.children {
                if (child.key == searchKey) {
                    childToUse = child
                    break
                }
            }
            
            //create a new node
            if  (childToUse == nil) {
                childToUse = TrieNode()
                childToUse.key = searchKey
                childToUse.level = current.level + 1
                current.children.append(childToUse)
            }
            
            current = childToUse
        }
        
        //add final end of word check
        if (keyword.length == current.level) {
            current.isFinal = true
            // print("end of word reached!")
            return
        }
    }
}