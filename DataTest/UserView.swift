//
//  UserView.swift
//  DataTest
//
//  Created by Test on 5/13/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import Foundation
import YapDatabase

class CurrentUserView: Viewable {
    typealias ObjectType = User
    typealias MetadataType = [String: AnyObject]
    
    static let name = "CurrentUser"
    
    let groupType = ViewType.Metadata
    let sortType = ViewType.Row
    
    
    func group(transaction: YapDatabaseReadTransaction, collection: String, key: String, object: User!, metadata: [String:AnyObject]?) -> String? {
        if let current = metadata?["current"] as? Bool where collection == User.collectionName {
//        if let DataSource.instance.currentUser?.key {
            return current ? "current" : nil
        }else{
            return nil
        }
    }
    
    func sort(transaction: YapDatabaseReadTransaction, group: String,
              collectionLeft: String, keyLeft: String, objectLeft: User!, metadataLeft: [String:AnyObject]?,
              collectionRight: String, keyRight: String, objectRight: User!, metadataRight: [String:AnyObject]?) -> NSComparisonResult {
        return NSComparisonResult.OrderedSame
    }
}