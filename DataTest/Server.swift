//
//  Server.swift
//  DataTest
//
//  Created by fixd on 5/10/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import YapDatabase
//import SwiftyJSON

extension Alamofire.Method {
    
    private var encoding: ParameterEncoding {
        switch self {
        case .HEAD:
            fallthrough
        case .GET:
            fallthrough
        case .DELETE:
            return ParameterEncoding.URLEncodedInURL
        default:
            return ParameterEncoding.JSON
        }
    }
}

extension Operation {
    
    private var method: Alamofire.Method {
        switch self {
        case .Find:
            fallthrough
        case .Query:
            return Alamofire.Method.GET
        case .Create:
            return Alamofire.Method.POST
        case .Update:
            return Alamofire.Method.PUT
        case .Destroy:
            return Alamofire.Method.DELETE
        }
    }
}

class Server {
    
    static let instance = Server(baseURL: NSURL(string: "https://fixdapp.ngrok.io/api/v2/")!)
    
    let baseURL: NSURL
    
    var headers: [String : String] = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Verbose-Response": "false"
    ]
    
    private init(baseURL: NSURL){
        self.baseURL = baseURL
    }
    
    private static func wasUnserializable(e: NSError) -> Bool {
        return e.domain == Alamofire.Error.Domain && e.code == Alamofire.Error.Code.DataSerializationFailed.rawValue
    }
    
    /**
     * Lightweight wrapper for Alamofire which uses stored headers by default and handles relative paths
     */
    func request(
        path: String,
        method: Alamofire.Method,
        encoding: ParameterEncoding = .JSON,
        parameters: [String: AnyObject]? = nil,
        headers: [String:String]? = nil
    ) -> Request {
        let url = NSURL(string: path, relativeToURL: baseURL)!
        let requestHeaders = headers ?? self.headers
        return Alamofire.request(method, url, parameters: parameters, encoding: encoding, headers: requestHeaders)
    }
    
//    private func handleNetworkError(request: Request) -> Request {
//        return request.responseJSON { response in
//            if let x = response.result.value as? [String:AnyObject] {
//                
//            }
//        }
//        return request
//    }
    
    /**
     * request method based on the FIXD api. Attempts to serialize the given object. Use for Find,Create,Update,Destroy
     */
    func requestMappable<T: Model>(
        object: T? = nil,
        path: String? = nil,
        op: Operation,
        parameters: [String: AnyObject]? = nil,
        headers: [String:String]? = nil
    ) -> Promise<T> {
        if object == nil && path == nil {
            fatalError("Must supply either object or path!")
        }
        return Promise {fulfill, reject in
            var stoppedForError = false
            var data: [String:AnyObject] = [:]
            if let object = object {
                data = data + [T.self.requestJSONKey : object.toJSON()]
            }
            if let parameters = parameters {
                data = data + parameters
            }
            let path = path ?? object!.getPathForOperation(op)
            self.request(path,
                method: op.method,
                encoding: op.method.encoding,
                parameters: data,
                headers: headers
            ).responseObject { (response: Response<NetworkError, NSError>) in
                if let e = response.result.value {
                    reject(e)
                    stoppedForError = true
                }else if let e = response.result.error {
                    if !Server.wasUnserializable(e){
                        reject(e)
                        stoppedForError = true
                    }
                }
            }.responseObject(keyPath: T.self.responseJSONKey) { (response: Response<T, NSError>) in
                if stoppedForError {
                    return
                }else if let e = response.result.error {
                    reject(e)
                }else if let v = response.result.value {
                    fulfill(v)
                }else{
                    reject(Error.errorWithCode(.JSONSerializationFailed, failureReason: "Unable to map response to type \(T.self): \(response)"))
                }
            }
        }
    }
    
    func create<T: Model>(object: T, path: String? = nil, parameters: [String: AnyObject]? = nil) -> Promise<T> {
        return requestMappable(object, path: path, op: .Create, parameters: parameters).thenInBackground { newObject -> T in
            Database.instance.writeChanges() { transaction in
                if let key = newObject.key, let object = newObject as? AnyObject {
                    transaction.setObject(object, forKey: key, inCollection: T.self.collectionName)
                }
            }
            return newObject
        }
    }
    
    func update<T: Model>(object: T, path: String? = nil, parameters: [String: AnyObject]? = nil, block: ((YapDatabaseReadWriteTransaction, T) -> Void)) -> Promise<T> {
        return Promise().thenInBackground {
            Database.instance.beginChangesToItem(object, block: block)
        }.then { _ in
            return self.requestMappable(object, path: path, op: .Update, parameters: parameters)
        }.thenInBackground { newObject in
            Database.instance.writeChanges() { transaction in
                if let key = newObject.key, let object = newObject as? AnyObject {
                    transaction.setObject(object, forKey: key, inCollection: T.self.collectionName)
                }
            }
            return Promise(newObject)
        }
    }
    
    func destroy<T: Model>(object: T, path: String? = nil, parameters: [String:AnyObject]? = nil) -> Promise<T> {
        let newObject: T = object.duplicate()!
        return requestMappable(newObject, path: path, op: .Destroy, parameters: parameters).thenInBackground { _ -> T in
            Database.instance.writeChanges() { transaction in
                if let key = newObject.key, let object = newObject as? AnyObject {
                    transaction.setObject(object, forKey: key, inCollection: T.self.collectionName)
                }
            }
            return newObject
        }
    }
    
    func find<T: Model>(path: String, parameters: [String:AnyObject]? = nil) -> Promise<T> {
        return requestMappable(nil, path: path, op: .Find, parameters: parameters).thenInBackground { (object: T) -> Promise<T> in
            Database.instance.writeChanges() { transaction in
                if let key = object.key {
                    transaction.setObject(object as? AnyObject, forKey: key, inCollection: T.self.collectionName)
                }
            }
            return Promise(object)
        }
    }
    
    func query<T: Model>(path: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil) -> Promise<[T]> {
            return Promise {fulfill, reject in
                self.request(path, method: .GET, encoding: .URLEncodedInURL, parameters: parameters, headers: headers).responseObject { (response: Response<NetworkError, NSError>) in
                    if let e = response.result.value {
                        reject(e)
                    }else if let e = response.result.error {
                        if !Server.wasUnserializable(e){
                            reject(e)
                        }
                    }
                }.responseArray(keyPath: T.self.responseJSONKey) { (response: Response<[T], NSError>) in
                    if let e = response.result.error {
                        reject(e)
                    }else if let v = response.result.value {
                        fulfill(v)
                    }else{
                        reject(Error.errorWithCode(.JSONSerializationFailed, failureReason: "Unable to map response to type \(T.self): \(response)"))
                    }
                }
            }
    }
}

//func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
//    for (k, v) in right {
//        
//        left.updateValue(v, forKey: k)
//    }
//}

//func += <K>(inout left: Dictionary<K, AnyObject>, right: Dictionary<K, AnyObject>) {
//    for (k,v) in right {
//        if let b = v as? Dictionary<K, AnyObject>, var a = left[k] as? Dictionary<K, AnyObject> {
//            a += b
////            left.updateValue(, forKey: k)
//        }else{
//            left.updateValue(v, forKey: k)
//        }
//    }
//}

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


//class TimestampMetadata: Mappable {
//    
//    var createdAt: NSDate?
//    var updatedAt: NSDate?
//    var insertedAt = NSDate()
//    
//    required init?(_ map: Map) {
//        
//    }
//    
//    func mapping(map: Map) {
//        createdAt <- map["created_at"]
//        updatedAt <- map["updated_at"]
//        //incoming json from server will never have this,
//        //  but we want to store it in serialization
//        insertedAt <- map["_inserted_at"]
//    }
//}

class NetworkError: NSError, Mappable {
    
    required init?(_ map: Map) {
        if map["status"].value() == "ERROR", let type: String = map["error.type"].value() {
            super.init(domain: type, code: NetworkError.getCode(type), userInfo: map["error"].value())
        }else{
            // annoyingly we have to call init even though the initializer fails
            super.init(domain: "_", code: 0, userInfo: nil)
            return nil
        }
    }
    
    override var localizedDescription: String {
        if let message = userInfo["message"] as? String {
            return message
        }
        return "(null)"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func mapping(map: Map) {
        //no-op. since NSErrors are immutable, we have to do mapping on init
    }
    
    private static func getCode(type: String) -> Int {
        switch type {
        case "NOT_FOUND":
            return 404
        case "FORBIDDEN":
            return 403
        case "NOT_AUTHENTICATED":
            return 401
        case "NO_SUCH_ROUTE":
            return 400
        case "BAD_FORMAT":
            return 400
        case "SERVER_ERROR":
            return 500
        default:
            return -1
        }
    }
}