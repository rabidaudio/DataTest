//
//  Model.swift
//  DataTest
//
//  Created by fixd on 5/2/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import ObjectMapper



//class Test: NSObject, NSCoding {
//    
//    override init() {}
//    
//    required init?(_ x: String){
//        
//    }
//    
//    required convenience init?(coder aDecoder: NSCoder) {
//        if let x = aDecoder.decodeObject() as? String {
//            if let y = x.stringByRemovingPercentEncoding {
//                self.init(y)
//            }else{
//                return nil
//            }
//        }else{
//            return nil
//        }
//    }
//    
//    func encodeWithCoder(aCoder: NSCoder) {
//    
//    }
//}
//
//class MyTest: Test {
//    
//    var z = "aloha"
//}

//protocol Smappable {
//    
//    init?(_ map: String)
//    
//}

class Model: NSObject, NSCoding, Mappable {
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(Mapper().toJSONString(self))
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        if let jsonString = aDecoder.decodeObject() as? String {
            if let jsonDict = Model.parseJSONStringToDictonary(jsonString) {
                let map = Map(mappingType: .FromJSON, JSONDictionary: jsonDict)
                self.init(map)
            }else{
                return nil
            }
        }else {
            return nil
        }
    }
    
    required init?(_ map: Map) {
        super.init()
        mapping(map)
    }
    
    func mapping(map: Map) {
        // override me!
    }

    func key() -> String? {
        // override me!
        return nil
    }
    
    override var description: String {
        return self.toJSONString(true)!
    }
    
    //Mapper will do this, but annoyingly, Swift complains about ambiguous parseJSONDictionary
    private static func parseJSONStringToDictonary(JSON: String) -> [String:AnyObject]? {
        let data = JSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        if let data = data {
            let parsedJSON: AnyObject?
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch let error {
                print(error)
                parsedJSON = nil
            }
            if let m = parsedJSON as? [String:AnyObject] {
                return m
            }
        }
        return nil
    }
    
    func duplicate<T: Model>() -> T? {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T

    }
}

extension NSCoding {

}

//
//enum Operation {
//    case Find, Query, Create, Update, Destroy
//}
//
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
//
//extension Alamofire.Method {
//    
//    private var encoding: ParameterEncoding {
//        switch self {
//        case .HEAD:
//            fallthrough
//        case .GET:
//            fallthrough
//        case .DELETE:
//            return ParameterEncoding.URLEncodedInURL
//        default:
//            return ParameterEncoding.JSON
//        }
//    }
//    
//}
//
//private func requestForJSON(method: Alamofire.Method, url: URLStringConvertible, parameters: [String:AnyObject] = [:], headers: [String:String] = [:]) -> Promise<(NSHTTPURLResponse, JSON)> {
//    
//    return Promise(resolvers: {fulfill, reject in
//        Alamofire.request(method, url, parameters: parameters, encoding: method.encoding, headers: headers).responseJSON { response in
//            switch response.result {
//            case .Success:
//                if let value = response.result.value, let response = response.response {
//                    let json = JSON(value)
//                    if let e = NetworkError(response: response, representation: json) {
//                        reject(e)
//                    }else{
//                        fulfill(response, json)
//                    }
//                }else{
//                    reject(Error.errorWithCode(.JSONSerializationFailed, failureReason: "Nil response"))
//                }
//            case .Failure(let error):
//                reject(error)
//            }
//        }
//    })
//}
//
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
//
//// type, message, id, method, path
//enum NetworkError: ErrorType, ResponseObjectSerializable {
//    
//    case NotFound(id: String, message: String)
//    case Forbidden(id: String, message: String)
//    case NotAuthenticated(id: String, message: String)
//    case NoSuchRoute(id: String, message: String)
//    case BadFormat(id: String, message: String)
//    case ServerError(id: String, message: String)
//    
//    init?(response: NSHTTPURLResponse, representation: JSON) {
//        if representation["status"].string != "ERROR" {
//            return nil
//        }
//        if let err = representation["error"].dictionary {
//            let id = err["id"]!.string!
//            let message = err["message"]!.string!
//            if let type = representation["type"].string {
//                switch type {
//                case "NOT_FOUND":
//                    self = .NotFound(id: id, message: message)
//                case "FORBIDDEN":
//                    self = .Forbidden(id: id, message: message)
//                case "NOT_AUTHENTICATED":
//                    self = .NotAuthenticated(id: id, message: message)
//                case "NO_SUCH_ROUTE":
//                    self = .NoSuchRoute(id: id, message: message)
//                case "BAD_FORMAT":
//                    self = .BadFormat(id: id, message: message)
//                case "SERVER_ERROR":
//                    self = .ServerError(id: id, message: message)
//                default:
//                    return nil
//                }
//            }else{
//                return nil
//            }
//        }else{
//            return nil
//        }
//    }
//}
//
//
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