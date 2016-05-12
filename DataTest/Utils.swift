//
//  Utils.swift
//  DataTest
//
//  Created by fixd on 5/11/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation

// recursive non-mutating dictonary merge
func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        if let l = map[k] as? Dictionary<K,V>, let r = v as? Dictionary<K,V> {
            map[k] = ((l + r) as! V)
        }else{
            map[k] = v
        }
    }
    return map
}

func += <K,V>(inout left: Dictionary<K,V>, right: Dictionary<K,V>) {
    left = left + right
}

extension Int {
    
    var string: String {
        return String(self)
    }
    
}

extension String {
    func toSnakeCase() -> String {
        var result = ""
        for c in self.lowerFirstLetter().characters {
            let sc = String(c)
            if sc == sc.lowercaseString {
                result += sc
            }else{
                result += "_\(sc.lowercaseString)"
            }
        }
        return result
    }
    
    func lowerFirstLetter() -> String {
        var clone = String(self)
        let firstLetter = clone.removeAtIndex(clone.startIndex)
        return String(firstLetter).lowercaseString + clone
    }
    
    func upperFirstLetter() -> String {
        var clone = String(self)
        let firstLetter = clone.removeAtIndex(clone.startIndex)
        return String(firstLetter).uppercaseString + clone
    }
}