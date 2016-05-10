
//  ViewController.swift
//  DataTest
//
//  Created by fixd on 5/2/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import UIKit

import YapDatabase
import ObjectMapper

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let baseDir: NSString = paths.first ?? NSTemporaryDirectory()
        let path = baseDir.stringByAppendingPathComponent("fixd.sqlite")
        let database = YapDatabase(path: path)
        
        let connection = database.newConnection()
        
        let mmy1String = "{\"id\": 1, \"make\": \"Make\", \"model\": \"Model\", \"year\": 2000}"
        let mmy2String = "{\"id\": 2, \"make\": \"Foo\", \"model\": \"Bar\"}"
        
        let mmy1 = Mapper<MakeModelYear>().map(mmy1String)
        let mmy2 = Mapper<MakeModelYear>().map(mmy2String)
        
        var mmyFirst, mmySecond: MakeModelYear!
        connection.readWriteWithBlock() { transaction in
            transaction.removeAllObjectsInAllCollections()
            transaction.setObject(mmy1!, forKey: mmy1!.key()!, inCollection: "make_model_year")
            transaction.setObject(mmy2!, forKey: mmy2!.key()!, inCollection: "make_model_year")
            
            mmyFirst = transaction.objectForKey("1", inCollection: "make_model_year") as! MakeModelYear
            mmySecond = transaction.objectForKey("2", inCollection: "make_model_year") as! MakeModelYear
        }
        
        print("items: \(mmyFirst) \(mmySecond)")
        
        print("copy: \(mmyFirst.duplicate()), \(mmySecond.duplicate()! == mmy2!)")
        
    }
}

