//
//  DataSource.swift
//  DataTest
//
//  Created by fixd on 5/11/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import PromiseKit

enum Operation {
    case Find, Query, Create, Update, Destroy
}

class DataSource {
    
    let server = Server(baseURL: NSURL(string: "https://fixdapp.ngrok.io/api/v2/")!)
    
    let database = Database()
    
    init(){
        server.headers["X-Verbose-Response"] = "false"
    }
    
    func create<T: Model>(object: T, path: String? = nil, parameters: [String: AnyObject]? = nil) -> Promise<T> {
        let copy: T = object.duplicate()!
        return self.server.requestModel(copy, path: path, op: .Create, parameters: parameters).thenInBackground { newObject -> T in
            return self.database.saveItemAsIs(newObject)
        }
    }
    
    func update<T: Model>(object: T, path: String? = nil, parameters: [String: AnyObject]? = nil, block: T -> T) -> Promise<T> {
        let updatedCopy = block(object.duplicate()!)
        return self.server.requestModel(updatedCopy, path: path, op: .Update, parameters: parameters).thenInBackground { newObject -> T in
            return self.database.saveItemAsIs(newObject)
        }
    }
    
    func destroy<T: Model>(object: T, path: String? = nil, parameters: [String:AnyObject]? = nil) -> Promise<T> {
        let copy: T = object.duplicate()!
        return self.server.requestModel(copy, path: path, op: .Destroy, parameters: parameters).thenInBackground { _ -> T in
            self.database.writeChanges() { transaction in
                if let key = copy.key {
                    transaction.removeObjectForKey(key, inCollection: T.self.collectionName)
                }
            }
            return copy
        }
    }
    
    func find<T: Model>(path: String, parameters: [String:AnyObject]? = nil) -> Promise<T> {
        return self.server.requestModel(nil, path: path, op: .Find, parameters: parameters).thenInBackground { (object: T) -> T in
            return self.database.saveItemAsIs(object)
        }
    }
    
    func query<T: Model>(path: String, parameters: [String:AnyObject]? = nil) -> Promise<[T]> {
        return self.server.requestModelArray(path, parameters: parameters).then { results -> [T] in
            return self.database.saveItemsAsIs(results)
        }
    }
}