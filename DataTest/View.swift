//
//  View.swift
//  DataTest
//
//  Created by Test on 5/13/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import YapDatabase
import YapDatabase.YapDatabaseView

enum ViewType {
    case Row, Object, Key, Metadata
}

protocol Viewable {
    associatedtype ObjectType
    associatedtype MetadataType
    
    static var name: String { get }
    static var collectionName: String { get }
    
    var groupType: ViewType { get }
    var sortType: ViewType { get }
    
    var versionTag: String? { get }
    
    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: ObjectType!, metadata: MetadataType?) -> String?
    
    
    func sort(transaction: YapDatabaseReadTransaction, group: String,
              collectionLeft: String, keyLeft: String, objectLeft: ObjectType!, metadataLeft: MetadataType?,
              collectionRight: String, keyRight: String, objectRight: ObjectType!, metadataRight: MetadataType?) -> NSComparisonResult
}

extension Viewable {
    
    var versionTag: String?{
        return "0"
    }
    
    private var grouping: YapDatabaseViewGrouping {
        switch(groupType){
        case .Key:
            return YapDatabaseViewGrouping.withKeyBlock() { t, c, k in
                guard c == self.dynamicType.collectionName else { return nil }
                return self.group(t, collection: c, key: k, object: nil, metadata: nil)
            }
        case .Object:
            return YapDatabaseViewGrouping.withObjectBlock() { t, c, k, o in
                guard c == self.dynamicType.collectionName else { return nil }
                if let o = o as? ObjectType {
                    return self.group(t, collection: c, key: k, object: o, metadata: nil)
                }else{
                    return nil
                }
            }
        case .Metadata:
            return YapDatabaseViewGrouping.withMetadataBlock() { t, c, k, m in
                guard c == self.dynamicType.collectionName else { return nil }
                return self.group(t, collection: c, key: k, object: nil, metadata: m as? MetadataType)
            }
        case .Row:
            return YapDatabaseViewGrouping.withRowBlock() { t, c, k, o, m in
                guard c == self.dynamicType.collectionName else { return nil }
                if let o = o as? ObjectType {
                    return self.group(t, collection: c, key: k, object: o, metadata: m as? MetadataType)
                }else{
                    return nil
                }
            }
        }
    }
    
    private var sorting: YapDatabaseViewSorting {
        switch(sortType){
        case .Key:
            return YapDatabaseViewSorting.withKeyBlock() { t, g, c1, k1, c2, k2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: nil, metadataLeft: nil, collectionRight: c2, keyRight: k2, objectRight: nil, metadataRight: nil)
            }
        case .Object:
            return YapDatabaseViewSorting.withObjectBlock() { t, g, c1, k1, o1, c2, k2, o2 in
                if let o1 = o1 as? ObjectType, o2  = o2 as? ObjectType {
                    return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: o1, metadataLeft: nil, collectionRight: c2, keyRight: k2, objectRight: o2, metadataRight: nil)
                }else{
                    return NSComparisonResult.OrderedSame
                }
            }
        case .Metadata:
            return YapDatabaseViewSorting.withMetadataBlock() { t, g, c1, k1, m1, c2, k2, m2 in
                return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: nil, metadataLeft: m1 as? MetadataType, collectionRight: c2, keyRight: k2, objectRight: nil, metadataRight: m2 as? MetadataType)
            }
        case .Row:
            return YapDatabaseViewSorting.withRowBlock() { t, g, c1, k1, o1, m1, c2, k2, o2, m2 in
                if let o1 = o1 as? ObjectType, o2 = o2 as? ObjectType {
                    return self.sort(t, group: g, collectionLeft: c1, keyLeft: k1, objectLeft: o1, metadataLeft: m1 as? MetadataType, collectionRight: c2, keyRight: k2, objectRight: o2, metadataRight: m2 as? MetadataType)
                }else{
                    return NSComparisonResult.OrderedSame
                }
            }
        }
    }
    
    private func build() -> YapDatabaseView {
        return YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: versionTag)
    }
    
    func addToDatabase(database: YapDatabase) {
        database.registerExtension(build(), withName: self.dynamicType.name)
    }
}

