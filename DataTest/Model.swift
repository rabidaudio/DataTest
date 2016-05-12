//
//  Model.swift
//  DataTest
//
//  Created by fixd on 5/2/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import ObjectMapper
import Pluralize_swift

//NOTE: I'd love to make Model inherit NSCopying, but you can't add an objc extension method to a Swift protocol
// (if you try, compiler will SegFault because the method is missing @objc, but you can't add @objc to an extension)

protocol Model: Mappable {
    
    var key: String? { get }
    
    static var entityName: String { get }
    
    func getPathForOperation(op: Operation) -> String
    
    static var requestJSONKey: String { get }
    static var responseJSONKey: String { get }
    static var collectionName: String { get }
}

extension Model {
    
    // empty initializer
    init(){
        let m = Map(mappingType: .FromJSON, JSONDictionary: [:])
        self.init(m)!
    }
    
    func getPathForOperation(op: Operation) -> String {
        let basePath = Pluralize.apply(Self.entityName.lowercaseString).toSnakeCase()
        switch(op){
        case .Create:
            fallthrough
        case .Query:
            return basePath
        case .Find:
            fallthrough
        case .Create:
            fallthrough
        case .Update:
            fallthrough
        case .Destroy:
            return "\(basePath)/\(key)"
        }
    }

    static var responseJSONKey: String {
        return "data"
    }
    
    static var requestJSONKey: String {
        return Self.entityName.toSnakeCase()
    }
    
    static var collectionName: String {
        return entityName
    }
    
    // make a copy of the item by encoding and then decoding
    // we use generics so we don't have to type convert the thing after duplication
    func duplicate() -> Self {
        let map = Map(mappingType: .FromJSON, JSONDictionary: self.toJSON())
        var t = self.dynamicType.init(map)!
        t.mapping(map)
        return t
    }
}
