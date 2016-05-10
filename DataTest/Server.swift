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
import SwiftyJSON

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

class Server {
    
    static let instance = Server(baseURL: NSURL(string: "http://localhost:3000/api/v2")!)
    
    let baseURL: NSURL
    
    var headers: [String : String] = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]
    
    private init(baseURL: NSURL){
        self.baseURL = baseURL
    }
    
    func request(path: String, method: Alamofire.Method, parameters: [String: AnyObject]? = nil, headers: [String:String]? = nil) -> Promise<(NSHTTPURLResponse, JSON)> {
        let url = NSURL(string: path, relativeToURL: baseURL)!
        let requestHeaders = headers ?? self.headers
        return Promise(resolvers: {fulfill, reject in
            Alamofire.request(method, url, parameters: parameters, encoding: method.encoding, headers: requestHeaders).responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value, let response = response.response {
                        let json = JSON(value)
                        if let e = NetworkError(response: response, representation: json) {
                            reject(e)
                        }else{
                            fulfill(response, json)
                        }
                    }else{
                        reject(Error.errorWithCode(.JSONSerializationFailed, failureReason: "Nil response"))
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        })
    }
}


// type, message, id, method, path
enum NetworkError: ErrorType {
    
    case NotFound(id: String, message: String)
    case Forbidden(id: String, message: String)
    case NotAuthenticated(id: String, message: String)
    case NoSuchRoute(id: String, message: String)
    case BadFormat(id: String, message: String)
    case ServerError(id: String, message: String)
    
    init?(response: NSHTTPURLResponse, representation: JSON) {
        if representation["status"].string != "ERROR" {
            return nil
        }
        if let err = representation["error"].dictionary {
            let id = err["id"]!.string!
            let message = err["message"]!.string!
            if let type = representation["type"].string {
                switch type {
                case "NOT_FOUND":
                    self = .NotFound(id: id, message: message)
                case "FORBIDDEN":
                    self = .Forbidden(id: id, message: message)
                case "NOT_AUTHENTICATED":
                    self = .NotAuthenticated(id: id, message: message)
                case "NO_SUCH_ROUTE":
                    self = .NoSuchRoute(id: id, message: message)
                case "BAD_FORMAT":
                    self = .BadFormat(id: id, message: message)
                case "SERVER_ERROR":
                    self = .ServerError(id: id, message: message)
                default:
                    return nil
                }
            }else{
                return nil
            }
        }else{
            return nil
        }
    }
}