//
//  JaroWinklerDistance.swift
//  ggchat
//
//  Created by Gary Chang on 12/7/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
extension String {
  
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(
            start: self.startIndex.advancedBy(r.startIndex),
            end: self.startIndex.advancedBy(r.endIndex)))
    }
    
    var length: Int {
        return self.characters.count
    }
}

class JaroWinkler {
    
    let INDEX_NOT_FOUND = -1
    let EMPTY = ""
    let SPACE = " "
    
    
    func getDistance(firstWord : String, secondWord : String) -> Float {
        
        let defaultScalingFactor : Float = 0.1
        
        let jaro = Float(self.score(firstWord, secondString: secondWord))
        let cp = Float(self.commonPrefixLength(firstWord, second: secondWord))
        
        let matchScore : Float = jaro + defaultScalingFactor * Float(cp) * Float(1 - jaro)
        return matchScore
    }
    
    
    /**
     * Calculates the number of characters from the beginning of the strings that match exactly one-to-one,
     * up to a maximum of four (4) characters.
     * returns A number between 0 to 4
     
     */
    
    func commonPrefixLength(first : String, second: String) -> Int {
        let result = self.getCommonPrefix(first, second: second).length
        
        // Limit the result to 4.
        return result > 4 ? 4 : result
    }
    
    func getCommonPrefix(first: String, second: String) -> String {
        
        if first == "" {
            return EMPTY
        }
        
        let smallestIndexOfDiff = self.indexOfDifference(first, second: second)
        
        if smallestIndexOfDiff == INDEX_NOT_FOUND {
            // ALL STRINGS WERE IDENTICAL
            if first == "" {
                return EMPTY
            }
            return first
        }
        else if smallestIndexOfDiff == 0 {
            // there were no common initial characters
            return EMPTY
        }
        else {
            // we found a common initial character sequence
            
            let str = first
            return str.substringWithRange(Range<String.Index>(
                start: str.startIndex,
                end: str.startIndex.advancedBy(smallestIndexOfDiff)))
        }
    }
    
    
    func indexOfDifference(first : String, second: String) -> Int {
        
        if first == second {
            return INDEX_NOT_FOUND
        }
        var i = 0
        while i < first.length &&  i < second.length {
            if String(Array(arrayLiteral: first)[i]) != String(Array(arrayLiteral: second)[i]) {
                break
            }
            i++
        }
        
        if i < first.length || i < second.length {
            return i
        }
        
        return INDEX_NOT_FOUND
    }
    
    func score(firstString : String, secondString : String) -> Float {
        
        var shorter : String!
        var longer : String!
        
        // Determine which String is longer.
        if firstString.length > secondString.length {
            longer = firstString.lowercaseString
            shorter = secondString.lowercaseString
        }
        else {
            longer = secondString.lowercaseString
            shorter = firstString.lowercaseString
        }
        
        // Calculate the half length() distance of the shorter String.
        let halfLength = Int(shorter.length) / 2 + 1
        
        // Find the set of matching characters between the shorter and longer strings. Note that
        // the set of matching characters may be different depending on the order of the strings.
        
        let m1 = self.getSetOfMatchingCharacterWithin(shorter, second: longer, limit: halfLength)
        
        let m2 = self.getSetOfMatchingCharacterWithin(longer, second: shorter, limit: halfLength)
        
        // If one or both of the sets of common characters is empty, then
        // there is no similarity between the two strings.
        
        if m1.length == 0 || m2.length == 0 {
            return 0.0
        }
        
        // If the set of common characters is not the same size, then
        // there is no similarity between the two strings, either.
        
        if m1.length != m2.length {
            return 0.0
        }
        
        // Calculate the number of transposition between the two sets
        // of common characters.
        
        let transpositions = self.transpositions(m1, m2: m2)
        
        // Calculate the distance.
        
        let c1 = Float(m1.length) / Float(shorter.length)
        let c2 = Float(m2.length) / Float(longer.length)
        let c3 = Float(m1.length - transpositions) / Float(m1.length)
        
        let dist = (c1 + c2 + c3) / 3
        
        return dist
    }
    
    
    func getSetOfMatchingCharacterWithin(first : String, second : String, limit : Int ) -> String {
        
        var common = ""
        var copy = second.copy() as! String
        
        for i in 0 ..< first.length {
            let ch: String = first[i]
            
            // See if the character is within the limit positions away from the original position of that character.
            let jStart = max(0, i - limit)
            let jEnd = min(i + limit, second.length)
            
            if jStart < jEnd {
                for j in jStart ..< jEnd {
                    let cp: String = copy[j]
                    if cp == ch {
                        common = common + ch
                        let nsRange : NSRange = NSRange(location: j, length: 1)
                        copy = (copy as NSString).stringByReplacingCharactersInRange(nsRange, withString: "*")
                        break
                    }
                }
            }
        }
        
        return common
    }
    
    
    func transpositions(m1 : String, m2 : String) -> Int {
        var transpositions = 0
        
        for i in 0 ..< m1.length {
            let s1: String = m1[i]
            let s2: String = m2[i]
            if s1 != s2 {
                transpositions++
            }
        }
        
        return transpositions/2
    }
}