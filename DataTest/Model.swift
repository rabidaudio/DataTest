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

//class Model: NSObject, NSCoding, Mappable {
//    
//    func encodeWithCoder(aCoder: NSCoder) {
//        aCoder.encodeObject(Mapper().toJSONString(self))
//    }
//
//    required convenience init?(coder aDecoder: NSCoder){
//        if let jsonString = aDecoder.decodeObject() as? String {
//            self.init(json: jsonString)
//        }else {
//            return nil
//        }
//    }
//    
//    required init?(_ map: Map) {
//        super.init()
//        mapping(map)
//    }
//    
//    convenience init?(json: String){
//        if let jsonDict = Model.parseJSONStringToDictonary(json) {
//            let map = Map(mappingType: .FromJSON, JSONDictionary: jsonDict)
//            self.init(map)
//        }else{
//            return nil
//        }
//    }
//    
//    func mapping(map: Map) {
//        // override me!
//    }
//    
//    override var description: String {
//        return self.toJSONString(true)!
//    }
//    
//    //Mapper will do this, but annoyingly, Swift complains about ambiguous parseJSONDictionary
//    private static func parseJSONStringToDictonary(JSON: String) -> [String:AnyObject]? {
//        let data = JSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
//        if let data = data {
//            let parsedJSON: AnyObject?
//            do {
//                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
//            } catch let error {
//                print(error)
//                parsedJSON = nil
//            }
//            if let m = parsedJSON as? [String:AnyObject] {
//                return m
//            }
//        }
//        return nil
//    }
//
//    func duplicate<T: Model>() -> T? {
//        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
//        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T
//
//    }
//    
//    func editAndSave<T: Model>(block: T -> Void) {
//        Database.instance.beginChangesToItem(self) { transaction, item in
//            block(item as! T)
//            if let key = item.key(){
//                transaction.setObject(item, forKey: key, inCollection: item.collection())
//            }
//        }
//    }
//}

/*
class User: Model {

var id: Int?
var email: String?

var key: String? {
guard let id = id else { return nil }
return String(id)
}

func mapping(map: Map) {
id <- map["id"]
email <- map["email"]
}
}
*/

//NOTE: Can't use @objc methods in an extension, and NSCoding requires it!







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
    func duplicate<T: Model>() -> T? {
        let map = Map(mappingType: .FromJSON, JSONDictionary: self.toJSON())
        var t = T(map)
        t?.mapping(map)
        return t
    }
}
