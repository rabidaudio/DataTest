//
//  Database.swift
//  DataTest
//
//  Created by fixd on 5/10/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import YapDatabase
import YapDatabase.YapDatabaseView
import ObjectMapper

class User: Model {
    
    static let entityName = "user"
    
    var id: Int?
    var email: String?
    var authToken: String?
    var vehicles: [String]?
    
    required init?(_ map: Map) {
        
    }
    
    var key: String? {
        return id?.string
    }
    
    func mapping(map: Map) {
        id        <- map["id"]
        email     <- map["email"]
        authToken <- map["authentication_token"]
    }
}

class Vehicle: Model {

    static let entityName = "vehicle"
    
    var vin: String?
    var makeModelYearId: Int?
    
    required init?(_ map: Map) {
        
    }

    var key: String? {
        return vin
    }
    
    func mapping(map: Map) {
        vin <- map["vin"]
        makeModelYearId <- map["make_model_year_id"]
    }

}

class MakeModelYear: Model {
    
    static let entityName = "make_model_year"
    
    var id: Int?
    var make: String?
    var model: String?
    var year: Int?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        id    <- map["id"]
        make  <- map["make"]
        model <- map["model"]
        year  <- map["year"]
    }
    
    var key: String? {
        return id?.string
    }
}


class Database {
    
    
    static let modelClasses: [Model.Type] = [
        User.self,
        Vehicle.self,
        MakeModelYear.self
    ]
    
    // keep our database and collections private to enforce writes off-main
    private let database: YapDatabase
    private let uiConnection: YapDatabaseConnection
    private let backgroundConnection: YapDatabaseConnection
    
    init(){
        // get path for sqlite database (right from the docs)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let baseDir: NSString = paths.first ?? NSTemporaryDirectory()
        let path = baseDir.stringByAppendingPathComponent("fixd.sqlite")
        database = YapDatabase(path: path, serializer: Database.serialize, deserializer: Database.deserialize)
        
        database.registerExtension(CurrentUserView().build(), withName: "currentUser")
        
        
        uiConnection = database.newConnection()
        backgroundConnection = database.newConnection()
    }
    
    static func serialize(collection: String, key: String, object: AnyObject) -> NSData {
        if let object = object as? Model {
            // while we could serialize the JSON string directly, it is a bit more performant
            // to serialize the parameter mapping ([String:AnyObject]) format instead
            return NSKeyedArchiver.archivedDataWithRootObject(object.toJSON())
        }
//        return YapDatabase.defaultSerializer()(collection, key, object)
        fatalError("Object \(collection) \(key) was not Model type: \(object)")
    }
    
    // convert collection name to a type (needed for deserialize)
    private static var modelMap: [String: Model.Type] = {
        var m = [String: Model.Type]()
        for c in modelClasses {
            m[c.collectionName] = c
        }
        return m
    }()
    
    static func deserialize(collection: String, key: String, data: NSData) -> AnyObject {
        if let json = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject] {
            let map = Map(mappingType: .FromJSON, JSONDictionary: json, toObject: false)
            if let T = modelMap[collection], var object = T.init(map) {
                object.mapping(map)
                return object as! AnyObject
            }
        }
//        return YapDatabase.defaultDeserializer()(collection, key, data)
        fatalError("Problem deserializing \(collection) \(key)! data size: \(data.length)")
    }
    
    func beginLongLivedReadTransaction() -> ([NSNotification], YapDatabaseConnection) {
        return (uiConnection.beginLongLivedReadTransaction(), uiConnection)
    }
    
    func setChangeObserver(observer: AnyObject, selector: Selector) {
        NSNotificationCenter.defaultCenter()
            .addObserver(observer, selector: selector, name: YapDatabaseModifiedNotification, object: database)
    }
    
    func readItemForKey<T: Model>(key: String, inCollection: String?) -> T? {
        var t: T?
        uiConnection.readWithBlock() { transaction in
            t = transaction.objectForKey(key, inCollection: inCollection) as? T
        }
        return t
    }
    
    func readObjectsFromView<T: Model>(view: String, group: String) -> [T] {
        var ts = [T]()
        uiConnection.readWithBlock() { transaction in
            (transaction.ext(view) as? YapDatabaseViewTransaction)?.enumerateRowsInGroup(group) { c, k, o, m, i, p in
                if let o = o as? T {
                    ts[Int(i)] = o
                }
            }
        }
        return ts
    }
    
    /**
     * Begin a background transaction. Don't forget to duplicate any items before manipulating them, as
     * they are likely not thread-safe. If you are only changing one item, use beginChangesToItem() which
     * will do this for you automatically. Or simply use item.editAndSave()
     */
    func writeChanges(block: YapDatabaseReadWriteTransaction -> Void){
        if(NSThread.isMainThread()){
            fatalError("Don't open read-write transaction from main thread!")
        }
        backgroundConnection.readWriteWithBlock(block)
    }
    
    private func writeToTransaction(transaction: YapDatabaseReadWriteTransaction, item: Model) {
        if let key = item.key, let object = item as? AnyObject {
            transaction.setObject(object, forKey: key, inCollection: item.dynamicType.collectionName)
        }
    }
    
    /**
     *  Prepare a background write transaction, automatically duplicating the item given before use,
     *  where manipulations can be made safely. after the supplied block is completed, the object is saved
     */
    func changeItem<T: Model>(item: T, block: (T, YapDatabaseReadWriteTransaction) -> T) -> T {
        let copy = item.duplicate()
        var newValue: T?
        writeChanges() { transaction in
            newValue = block(copy, transaction)
            self.writeToTransaction(transaction, item: newValue!)
        }
        return newValue!
    }
    
    func saveItemAsIs<T: Model>(item: T) -> T {
        writeChanges() { transaction in
            self.writeToTransaction(transaction, item: item)
        }
        return item
    }
    
    func saveItemsAsIs<T: Model>(items: [T]) -> [T] {
        writeChanges() { transaction in
            for item in items {
                self.writeToTransaction(transaction, item: item)
            }
        }
        return items
    }
}