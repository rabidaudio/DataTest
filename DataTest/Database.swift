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
    
    required init?(_ map: Map) {
        
    }
    
    var key: String? {
        return id?.string
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        email <- map["email"]
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
        id <- map["id"]
        make <- map["make"]
        model <- map["model"]
        year <- map["year"]
    }
    
    var key: String? {
        return id?.string
    }
}

// TODO: Optimize Grouping types
//class View {
//    
//    lazy var view: YapDatabaseView = {
//        let grouping = YapDatabaseViewGrouping.withRowBlock(self.group)
//        let sorting = YapDatabaseViewSorting.withRowBlock(self.sort)
//        return YapDatabaseView(grouping: grouping, sorting: sorting)
//    }()
//    
//    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: AnyObject, metadata: AnyObject?) -> String? {
//        return nil
//    }
//    
//    func sort(transaction: YapDatabaseReadTransaction, group: String,
//        collectionLeft: String, keyLeft: String, objectLeft: AnyObject, metadataLeft: AnyObject?,
//        collectionRight: String, keyRight: String, objectRight: AnyObject, metadataRight: AnyObject?) -> NSComparisonResult {
//            return keyLeft.compare(keyRight)
//    }
//}

//class View<T: Model, M: AnyObject>: YapDatabaseView {
//    
////    private let group: (YapDatabaseReadTransaction, String, String, T, M?) -> String?
////    private let sort: (YapDatabaseReadTransaction, String, String, String, T, M?, String, String, T, M?) -> NSComparisonResult
//    
//    init(group: ((transaction: YapDatabaseReadTransaction, collection: String, key: String, object: T, metadata: M?) -> String?),
//        sort: ((transaction: YapDatabaseReadTransaction, group: String,
//            collectionLeft: String, keyLeft: String, objectLeft: T, metadataLeft: M?,
//            collectionRight: String, keyRight: String, objectRight: T, metadataRight: M?) -> NSComparisonResult)){
//                let g = YapDatabaseViewGrouping.withRowBlock() { t, c, k, o, m in
//                    if let o = o as? T {
//                        return group(transaction: t, collection: c, key: k, object: o, metadata: m as? M)
//                    }else{
//                        return nil
//                    }
//                }
//                
//                let s = YapDatabaseViewSorting.withRowBlock() { t, g, c1, k1, o1, m1, c2, k2, o2, m2 in
//                    if let o1 = o1 as? T, o2 = o2 as? T {
//                        return sort(transaction: t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: o1, metadataLeft: m1 as? M, collectionRight: c2, keyRight: k2, objectRight: o2, metadataRight: m2 as? M)
//                    }else{
//                        return NSComparisonResult(rawValue: 0)!
//                    }
//                }
//        super.init(grouping: g, sorting: s)
//    }
//}

protocol Groupable {
    
    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: AnyObject?, metadata: AnyObject?) -> String?
    
}

protocol Sortable {
    
    func sort(transaction: YapDatabaseReadTransaction, group: String,
                collectionLeft: String, keyLeft: String, objectLeft: AnyObject?, metadataLeft: AnyObject?,
                collectionRight: String, keyRight: String, objectRight: AnyObject?, metadataRight: AnyObject?) -> NSComparisonResult
    
}

protocol Viewable: Groupable, Sortable {
    
    var groupType: ViewType { get }
    var sortType: ViewType { get }
    
    var versionTag: String? { get }
}

extension Viewable {
    
    var versionTag: String?{
        return "0"
    }
    
    private func grouping() -> YapDatabaseViewGrouping {
        switch(groupType){
        case .Key:
            return YapDatabaseViewGrouping.withKeyBlock() { t, c, k in
                self.group(t, collection: c, key: k, object: nil, metadata: nil)
            }
        case .Object:
            return YapDatabaseViewGrouping.withObjectBlock() { t, c, k, o in
                self.group(t, collection: c, key: k, object: o, metadata: nil)
            }
        case .Metadata:
            return YapDatabaseViewGrouping.withMetadataBlock() { t, c, k, m in
                self.group(t, collection: c, key: k, object: nil, metadata: m)
            }
        case .Row:
            return YapDatabaseViewGrouping.withRowBlock() { t, c, k, o, m in
                self.group(t, collection: c, key: k, object: o, metadata: m)
            }
        }
    }private func sorting() -> YapDatabaseViewSorting {
        switch(sortType){
        case .Key:
            return YapDatabaseViewSorting.withKeyBlock() { t, g, c1, k1, c2, k2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: nil, metadataLeft: nil, collectionRight: c2, keyRight: k2, objectRight: nil, metadataRight: nil)
            }
        case .Object:
            return YapDatabaseViewSorting.withObjectBlock() { t, g, c1, k1, o1, c2, k2, o2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: o1, metadataLeft: nil, collectionRight: c2, keyRight: k2, objectRight: o2, metadataRight: nil)
            }
        case .Metadata:
            return YapDatabaseViewSorting.withMetadataBlock() { t, g, c1, k1, m1, c2, k2, m2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: nil, metadataLeft: m1, collectionRight: c2, keyRight: k2, objectRight: nil, metadataRight: m2)
            }
        case .Row:
            return YapDatabaseViewSorting.withRowBlock() { t, g, c1, k1, o1, m1, c2, k2, o2, m2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: o1, metadataLeft: m1, collectionRight: c2, keyRight: k2, objectRight: o2, metadataRight: m2)
            }
        }
    }
    
    func build() -> YapDatabaseView {
        return YapDatabaseView(grouping: grouping(), sorting: sorting(), versionTag: versionTag)
    }
    
}

enum ViewType {
    case Row, Object, Key, Metadata
}

class CurrentUserView: Viewable {
    
    let groupType = ViewType.Key
    let sortType = ViewType.Key
    
    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: AnyObject?, metadata: AnyObject?) -> String? {
        if key == "1" {
            return "current_user"
        }else{
            return nil
        }
    }
    
    func sort(transaction: YapDatabaseReadTransaction, group: String,
        collectionLeft: String, keyLeft: String, objectLeft: AnyObject?, metadataLeft: AnyObject?,
        collectionRight: String, keyRight: String, objectRight: AnyObject?, metadataRight: AnyObject?) -> NSComparisonResult {
        return NSComparisonResult.OrderedSame
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
        
//        YapDatabaseViewSorting.
        
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