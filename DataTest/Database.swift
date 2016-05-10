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
    
    var vin: String?
    
    var makeModelYearId: Int?
    
    override func mapping(map: Map) {
        vin <- map["vin"]
        makeModelYearId <- map["make_model_year_id"]
    }
    
}

class MakeModelYear: Model {
    
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
    
}



class Database {
    
    let database: YapDatabase
    
    private init(){
        // get path for sqlite database (right from the docs)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let baseDir: NSString = paths.first ?? NSTemporaryDirectory()
        let path = baseDir.stringByAppendingPathComponent("fixd.sqlite")
        database = YapDatabase(path: path)
    }
}