//
//  Database.swift
//  DataTest
//
//  Created by fixd on 5/10/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import YapDatabase
import ObjectMapper

class User: Model {
    
    static let entityName = "user"
    
    var id: Int?
    var email: String?
    
    required init?(_ map: Map) {
        
    }
    
    var key: String? {
        return idToString(id)
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        email <- map["email"]
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
        id <- map["id"]
        make <- map["make"]
        model <- map["model"]
        year <- map["year"]
    }
    
    var key: String? {
        return idToString(id)
    }
}



class Database {
    
    static private(set) var instance = Database()
    
    private let database: YapDatabase
    
    private let uiConnection: YapDatabaseConnection
    private let backgroundConnection: YapDatabaseConnection
    
    private init(){
        // get path for sqlite database (right from the docs)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let baseDir: NSString = paths.first ?? NSTemporaryDirectory()
        let path = baseDir.stringByAppendingPathComponent("fixd.sqlite")
        database = YapDatabase(path: path, serializer: Database.serialize, deserializer: Database.deserialize)
        
        uiConnection = database.newConnection()
        backgroundConnection = database.newConnection()
    }
    
    /*
    * defaultSerializer = ^(NSString *collection, NSString *key, id object){
    *     return [NSKeyedArchiver archivedDataWithRootObject:object];
    * };
    * defaultDeserializer = ^(NSString *collection, NSString *key, NSData *data) {
    *     return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    * };
    */
    
    static func serialize(collection: String, key: String, object: AnyObject) -> NSData {
        if let object = object as? Model {
            return NSKeyedArchiver.archivedDataWithRootObject(object.toJSON())
        }
        fatalError("Object \(collection) \(key) was not Model type: \(object)")
    }
    
    static func deserialize(collection: String, key: String, data: NSData) -> AnyObject {
        if let json = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject] {
            let map = Map(mappingType: .FromJSON, JSONDictionary: json, toObject: false)
            var object: AnyObject?
            switch(collection){
            case User.collectionName:
                object = User(map)
            case Vehicle.collectionName:
                object = Vehicle(map)
            case MakeModelYear.collectionName:
                object = MakeModelYear(map)
            default:
                break
            }
            if let object = object {
                return object
            }
        }
        fatalError("Problem deserializing \(collection) \(key)! data size: \(data.length)")
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
    
    /**
     *  Begin a background write transaction, automatically duplicating the item given before use
     */
    func beginChangesToItem<T: Model>(item: T, block: (YapDatabaseReadWriteTransaction, T) -> Void) {
        writeChanges() { transaction in
            block(transaction, item.duplicate()!)
        }
    }
}