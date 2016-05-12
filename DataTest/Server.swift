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
    
    private static func createPayload(object: Model?, parameters: [String: AnyObject]?) -> [String: AnyObject]{
        var data: [String: AnyObject] = [:]
        if let object = object {
            data = data + [object.dynamicType.requestJSONKey : object.toJSON()]
        }
        if let parameters = parameters {
            data = data + parameters
        }
        return data
    }
    
    /**
     * request method based on the FIXD api. Attempts to serialize the given object. Used for Find,Create,Update,Destroy
     */
    func requestModel<T: Model>(
        object: T? = nil,
        path: String? = nil,
        op: Operation,
        parameters: [String: AnyObject]? = nil,
        headers: [String:String]? = nil
    ) -> Promise<T> {
        if object == nil && path == nil {
            fatalError("Must supply either object or path!")
        }
        
        let (promise, fulfill, reject) = Promise<T>.pendingPromise()
        
        let path = path ?? object!.getPathForOperation(op)
        let method = op.method
        let encoding = op.method.encoding
        let data = Server.createPayload(object, parameters: parameters)
        
        self.request(path, method: method, encoding: encoding, parameters: data, headers: headers)
            .responseNetworkError(promise, reject: reject)
            .responseHandlePromise(T.self.responseJSONKey, promise: promise, fulfill: fulfill, reject: reject)
        
        return promise
    }
    
    func requestModelArray<T: Model>(path: String, parameters: [String: AnyObject]? = nil, headers: [String:String]? = nil) -> Promise<[T]> {
        let (promise, fulfill, reject) = Promise<[T]>.pendingPromise()
        self.request(path, method: .GET, encoding: .URLEncodedInURL, parameters: parameters, headers: headers)
            .responseNetworkError(promise, reject: reject)
            .responseArrayHandlePromise(T.self.responseJSONKey, promise: promise, fulfill: fulfill, reject: reject)
        
        return promise
    }
}

extension Request {
    
    public static func NetworkErrorSerializer() -> ResponseSerializer<NetworkError, NSError> {
        
        return ResponseSerializer { request, response, data, error in
            guard error == nil else { return .Failure(error!) }
            //proxy off ObjectMapperSerializer, but if mapping is success, fail with it
            let r: ResponseSerializer<NetworkError, NSError> = Request.ObjectMapperSerializer(nil, mapToObject: nil)
            let result = r.serializeResponse(request, response, data, error)
            if let netErr = result.value {
                return .Failure(netErr)
            }else{
                return result
            }
        }
    }
    
    // take in a promise which will be rejected if there was a problem
    public func responseNetworkError<T>(promise: Promise<T>, reject: (ErrorType->Void)) -> Self {
        return response(responseSerializer: Request.NetworkErrorSerializer()) { response in
            if promise.pending, let e = response.result.error where !(e as NSError).isObjectUnserializable {
                reject(e)
            }
        }
    }
    
    // filfill or reject a promise based on ability to object map
    public func responseHandlePromise<T: Mappable>(keyPath: String? = nil, promise: Promise<T>, fulfill: (T->Void), reject: (ErrorType->Void)) -> Self {
        return response(responseSerializer: Request.ObjectMapperSerializer(keyPath, mapToObject: nil) ){ (response: Response<T, NSError>) in
            if !promise.pending {
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
    
    // same as above for arrays
    public func responseArrayHandlePromise<T: Mappable>(keyPath: String? = nil, promise: Promise<[T]>, fulfill: ([T]->Void), reject: (ErrorType->Void)) -> Self {
        return response(responseSerializer: Request.ObjectMapperArraySerializer(keyPath)){ (response: Response<[T], NSError>) in
            if !promise.pending {
                return
            }else if let e = response.result.error {
                reject(e)
            }else if let v = response.result.value {
                fulfill(v)
            }else{
                reject(Error.errorWithCode(.JSONSerializationFailed, failureReason: "Unable to map array response to type \(T.self): \(response)"))
            }
        }
    }
}

extension NSError {
    private var isObjectUnserializable: Bool {
        return self.domain == Alamofire.Error.Domain
            && self.code == Alamofire.Error.Code.DataSerializationFailed.rawValue
    }
}


// TODO: saving timestamps as metadata on objects could be valueable for automatic caching of network responses
// maybe createdAt and updatedAt from the server, plus a local update and/or last network request timestamp
//class TimestampMetadata: Mappable {  }

/**
 *  Class representing error response objects from the server
 */
public class NetworkError: NSError, Mappable {
    
    required public init?(_ map: Map) {
        if map["status"].value() == "ERROR", let type: String = map["error.type"].value() {
            super.init(domain: type, code: NetworkError.getCode(type), userInfo: map["error"].value())
        }else{
            // annoyingly we have to call init even though the initializer fails
            super.init(domain: "_", code: 0, userInfo: nil)
            return nil
        }
    }
    
    override public var localizedDescription: String {
        return (userInfo["message"] as? String) ?? domain
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func mapping(map: Map) {
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