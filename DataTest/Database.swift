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


class Vehicle: Model {
    
    required init?(_ map: Map) {
        super.init(map)
    }
    
    var vin: String?
    
    var makeModelYearId: Int?
    
    override func mapping(map: Map) {
        vin <- map["vin"]
        makeModelYearId <- map["make_model_year_id"]
    }
    
    override func key() -> String? {
        return vin
    }
}

class MakeModelYear: Model {
    
    required init?(_ map: Map) {
        super.init(map)
    }
    
    var id: Int?
    var make: String?
    var model: String?
    var year: Int?
    
    override func mapping(map: Map) {
        id <- map["id"]
        make <- map["make"]
        model <- map["model"]
        year <- map["year"]
    }
    
    override func key() -> String? {
        guard let id = id else { return nil }
        return String(id)
    }
}



class Database {
    
    static private(set) var instance = Database()
    
    let database: YapDatabase
    
    private init(){
        // get path for sqlite database (right from the docs)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let baseDir: NSString = paths.first ?? NSTemporaryDirectory()
        let path = baseDir.stringByAppendingPathComponent("fixd.sqlite")
        database = YapDatabase(path: path)
        
//        let connection = database.newConnection()
        
//        let mmy1String = "{\"id\": 1, \"make\": \"Make\", \"model\": \"Model\", \"year\": 2000}"
//        let mmy2String = "{\"id\": 2, \"make\": \"Foo\", \"model\": \"Bar\"}"
//        
//        let mmy1 = Mapper<MakeModelYear>.parseJSONString(mmy1String) as! MakeModelYear
//        let mmy2 = Mapper<MakeModelYear>.parseJSONString(mmy2String) as! MakeModelYear
//        
//        
//        var mmyFirst, mmySecond: MakeModelYear!
//        connection.readWriteWithBlock() { transaction in
//            
//            transaction.setObject(mmy1, forKey: mmy1.key()!, inCollection: "make_model_year")
//            transaction.setObject(mmy2, forKey: mmy2.key()!, inCollection: "make_model_year")
//            
//            mmyFirst = transaction.objectForKey("1", inCollection: "make_model_year") as! MakeModelYear
//            mmySecond = transaction.objectForKey("2", inCollection: "make_model_year") as! MakeModelYear
//        }
//        
//        print("items: \(mmyFirst) \(mmySecond)")
    }
}