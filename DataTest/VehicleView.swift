//
//  VehicleView.swift
//  DataTest
//
//  Created by Test on 5/13/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import YapDatabase

class VehiclesView: Viewable {
    typealias ObjectType = Vehicle
    typealias MetadataType = [String: AnyObject]
    
    let groupType = ViewType.Key
    let sortType = ViewType.Key
    
    
    
    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: Vehicle!, metadata: [String:AnyObject]?) -> String? {
        if let userKey = DataSource.instance.currentUser?.key {
            
        }
        return nil
    }
    
    func sort(transaction: YapDatabaseReadTransaction, group: String,
              collectionLeft: String, keyLeft: String, objectLeft: Vehicle!, metadataLeft: [String:AnyObject]?,
              collectionRight: String, keyRight: String, objectRight: Vehicle!, metadataRight: [String:AnyObject]?) -> NSComparisonResult {
        return keyLeft.compare(keyRight)
    }
}