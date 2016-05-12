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

/**
 *  For GET and HEAD requests, put the data in the query string.
 *  For all other requests, encode as JSON in request body
 */
extension Alamofire.Method {
    private var encoding: ParameterEncoding {
        switch self {
        case .HEAD:
            fallthrough
        case .GET:
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
    
    let baseURL: NSURL
    
    var headers = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]
    
    init(baseURL: NSURL){
        self.baseURL = baseURL
    }
    
    private static func wasUnserializable(e: NSError) -> Bool {
        return e.domain == Alamofire.Error.Domain
            && e.code == Alamofire.Error.Code.DataSerializationFailed.rawValue
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
    
    private static func createPayload<T: Model>(object: T?, parameters: [String: AnyObject]?) -> [String: AnyObject]{
        var data: [String: AnyObject] = [:]
        if let object = object {
            data = data + [T.self.requestJSONKey : object.toJSON()]
        }
        if let parameters = parameters {
            data = data + parameters
        }
        return data
    }
    
    private func serializeError(msg: String) -> ErrorType {
        Error.errorWithCode(.JSONSerializationFailed, failureReason: "Unable to map response to type \(msg)")
    }
    
    /**
     * request method based on the FIXD api. Attempts to serialize the given object. Used for Find,Create,Update,Destroy
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
            
            let path = path ?? object!.getPathForOperation(op)
            
            self.request(path,
                method: op.method,
                encoding: op.method.encoding,
                parameters: Server.createPayload(object, parameters: parameters),
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
                    reject(self.serializeError("\(T.self): \(response)"))
                }
            }
        }
    }
    
    func requestMappableArray<T: Model>(path: String, parameters: [String: AnyObject]? = nil, headers: [String:String]? = nil) -> Promise<[T]> {
        return Promise {fulfill, reject in
            var stoppedForError = false
            self.request(path, method: .GET, encoding: .URLEncodedInURL, parameters: parameters, headers: headers).responseObject { (response: Response<NetworkError, NSError>) in
                if let e = response.result.value {
                    reject(e)
                    stoppedForError = true
                }else if let e = response.result.error {
                    if !Server.wasUnserializable(e){
                        reject(e)
                        stoppedForError = true
                    }
                }
            }.responseArray(keyPath: T.self.responseJSONKey) { (response: Response<[T], NSError>) in
                if stoppedForError {
                    return
                }
                if let e = response.result.error {
                    reject(e)
                }else if let v = response.result.value {
                    fulfill(v)
                }else{
                    reject(self.serializeError("\(T.self): \(response)"))
                }
            }
        }
    }
}

// TODO: saving timestamps as metadata on objects could be valueable for automatic caching of network responses
// maybe createdAt and updatedAt from the server, plus a local update and/or last network request timestamp
//class TimestampMetadata: Mappable {  }

/**
 *  Class representing error response objects from the server
 */
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
        return (userInfo["message"] as? String) ?? domain
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