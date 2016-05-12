
//  ViewController.swift
//  DataTest
//
//  Created by fixd on 5/2/16.
//  Copyright © 2016 fixd. All rights reserved.
//

import UIKit

import YapDatabase
import ObjectMapper
import PromiseKit

func doAsyncAfter(seconds: NSTimeInterval, task: (Void -> Void)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((seconds as Double) * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), task)
}

class ViewController: UIViewController {
    
    var user: User!
    
    let dataSource = DataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        user = User()
        user.email = "julian@fixdapp.com"
        
        self.dataSource.database.beginLongLivedReadTransaction()
        self.dataSource.database.setChangeObserver(self, selector: "onDatabaseChange:")
        
        dataSource.create(user, path: "users/current", parameters: ["user": ["password": ""]]).then { newUser -> Void in
            print("user created: \(newUser), \(self.user)")
            
            self.user = newUser
            
            doAsyncAfter(1) {
                Promise().thenInBackground {
                    self.dataSource.database.changeItem(self.user) { item, _ in
                        item.email = ":)"
                        return item
                    }
                }
            }
            
        }.error { err in
            print("err: \(err)")
        }
    }
    
    func onDatabaseChange(notification: NSNotification) {
        let (notifications, connection) = self.dataSource.database.beginLongLivedReadTransaction()
        if notifications.isEmpty {
            return
        }
        if connection.hasChangeForCollection(User.collectionName, inNotifications: notifications) {
            print("users changed")
        }
        if let key = user.key {
            if connection.hasChangeForKey(key, inCollection: User.collectionName, inNotifications: notifications) {
                self.user = self.dataSource.database.readItemForKey(key, inCollection: User.collectionName)
                print("user changed: \(user.email)")
            }
        }
    }
}

