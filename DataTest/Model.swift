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

func idToString(id: Int?) -> String? {
    guard let id = id else { return nil }
    return String(id)
}


enum Operation {
    case Find, Query, Create, Update, Destroy
}


protocol Model: Mappable {
    
    var key: String? { get }
    
    static var entityName: String { get }
    
    func getPathForOperation(op: Operation) -> String
    
    var requestJSONKey: String { get }
    var responseJSONKey: String { get }
    static var collectionName: String { get }
}

extension Model {
    
    // empty initializer
    init(){
        let m = Map(mappingType: .FromJSON, JSONDictionary: [:])
        self.init(m)!
    }
    
    func getPathForOperation(op: Operation) -> String {
        let basePath = Pluralize.apply(Self.entityName.lowercaseString)
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

    var responseJSONKey: String {
        return "data"
    }
    
    var requestJSONKey: String {
        return Self.entityName.lowercaseString
    }
    
    static var collectionName: String {
        return entityName
    }
    
    // make a copy of the item by encoding and then decoding
    // we use generics so we don't have to type convert the thing after duplication
    func duplicate<T: Model>() -> T? {
        return T(Map(mappingType: .FromJSON, JSONDictionary: self.toJSON()))
    }
}

//extension Model {
//    
//    func create(){
//        Server.instance.request(<#T##path: String##String#>, method: <#T##Method#>)
//    }
//}

//extension NSManagedObject {
//    
//    convenience init(context: NSManagedObjectContext){
//        let entity = NSEntityDescription.entityForName(NSManagedObject.entityName(), inManagedObjectContext: context)!
//        self.init(entity: entity, insertIntoManagedObjectContext: context)
//    }
//    
//    public class func entityName() -> String {
//        let name = NSStringFromClass(self)
//        return name.componentsSeparatedByString(".").last!
//    }
//
//}
//
//protocol Model: ResponseObjectSerializable {
//    typealias Id
//    
//    static var requestKey: String { get }
//    
//    static var responseKey: String { get }
//    
//    static func urlForOperation(operation: Operation) -> URLStringConvertible
//    
//    var serialized: [String: AnyObject] { get }
//}

//import PromiseKit
//import Alamofire
//import SwiftyJSON
//
//private func requestForJSON(method: Alamofire.Method, url: URLStringConvertible, parameters: [String:AnyObject] = [:], headers: [String:String] = [:]) -> Promise<(NSHTTPURLResponse, JSON)> {
//    
//}

//protocol Hashable {
//    
//    // create
//    init?(hash: [String : AnyObject])
//    
//    // serialize, update
//    var hash: [String : AnyObject] { get set }
//}
//
////protocol Entitied {
////
////    var entityName: String { get }
////}
//
////class HashableNSManagedObject: NSManagedObject, Model, Hashable {
////
////    required init?(hash: [String:AnyObject]) {
////        super.init(entity: NSEntityDescription.entityForName(Self.entityName, inManagedObjectContext: FixdApi.context), insertIntoManagedObjectContext: <#T##NSManagedObjectContext?#>)
////
////    }
////}
//
//
//extension Model {
//    
//    private static func serializeOne(response: NSHTTPURLResponse, json: JSON) throws -> Self {
//        if let x = Self(response: response, representation: json[responseKey]) {
//            return x
//        }else{
//            throw Error.errorWithCode(.JSONSerializationFailed, failureReason: "Problem serializing object")
//        }
//    }
//    
//    //    private static func serializeMany(response: NSHTTPURLResponse, json: JSON) throws -> [Self] {
//    //        if let array = json[responseKey].array {
//    //            var results: [Self] = []
//    //            for item in array {
//    //                try results.append(serializeOne(response, json: item))
//    //            }
//    //            return results
//    //        }else{
//    //            throw Error.errorWithCode(.JSONSerializationFailed, failureReason: "response was not array")
//    //        }
//    //    }
//    
//    static func find(url: URLStringConvertible? = nil, id: Id, parameters: [String: AnyObject] = [:]) -> Promise<Self?> {
//        return requestForJSON(.GET, url: url ?? urlForOperation(.Find), parameters: parameters).then(serializeOne)
//    }
//    
//    func create(url: URLStringConvertible? = nil, parameters: [String : AnyObject] = [:]) -> Promise<Self> {
//        let data = self.serialized + parameters
//        return requestForJSON(.POST, url: url ?? Self.urlForOperation(.Create), parameters: data).then(Self.serializeOne)
//    }
//}
//
//func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>)
//    -> Dictionary<K,V>
//{
//    var map = Dictionary<K,V>()
//    for (k, v) in left {
//        map[k] = v
//    }
//    for (k, v) in right {
//        map[k] = v
//    }
//    return map
//}
//public protocol ResponseObjectSerializable {
//    init?(response: NSHTTPURLResponse, representation: JSON)
//}
//
////enum SimpleType {
////    case String, Int, Double, Date, Bool
////}
//
//class JSONMapper<T> {
//    
//    private var keyMapping: [String : String] = [:]
//    
//    private var serializerMapping: [String : (T) throws -> AnyObject] = [:]
//    private var deserializerMapping: [String: (AnyObject, String, T) throws -> Void] = [:]
//    
//    func addProp(name: String, key: String? = nil, serialize: Bool = true, deserialize: Bool = true, serializer: ((val: T) throws -> AnyObject)?, deserializer: ((val: AnyObject, propName: String, object: T) throws -> Void)?){
//        keyMapping[name] = key ?? name.toSnakeCase()
//        if serialize {
//            serializerMapping[name] = serializer
//        }
//        if deserialize {
//            deserializerMapping[name] = deserializer
//        }
//    }
//    
//    func serialize(object: T) throws -> [String : AnyObject] {
//        var result: [String : AnyObject] = [:]
//        for (name, key) in keyMapping {
//            if let s = serializerMapping[name] {
//                try result[key] = s(object)
//            }
//        }
//        return result
//    }
//    
//    func deserialize(object: T, data: [String : AnyObject]) throws {
//        for (name, key) in keyMapping {
//            if let d = deserializerMapping[name], let v = data[key] {
//                try d(v, name, object)
//            }
//        }
//    }
//}
//
//class ManagedObjectMapper<T:NSManagedObject>: JSONMapper<T> {
//    
//    static func stringSerialize(val: T, name: String) -> String {
//        return val.valueForKey(name) as String
//    }
//    
//    
//}
//
//
//extension String {
//    private func toSnakeCase() -> String {
//        var result = ""
//        for c in self.lowerFirstLetter().characters {
//            let sc = String(c)
//            if sc == sc.lowercaseString {
//                result += sc
//            }else{
//                result += "_\(sc.lowercaseString)"
//            }
//        }
//        return result
//    }
//    
//    func lowerFirstLetter() -> String {
//        var clone = String(self)
//        let firstLetter = clone.removeAtIndex(clone.startIndex)
//        return String(firstLetter).lowercaseString + clone
//    }
//    
//    func upperFirstLetter() -> String {
//        var clone = String(self)
//        let firstLetter = clone.removeAtIndex(clone.startIndex)
//        return String(firstLetter).uppercaseString + clone
//    }
//}