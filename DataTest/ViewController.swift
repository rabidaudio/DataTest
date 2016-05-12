
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
    
    var user: User!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        user = User()
        user.email = "woopee@doo"
        
        Server.instance.create(user, parameters: ["user": ["password": "password"]]).then { newUser -> Void in
            print("user created: \(newUser), \(self.user)")
            
            Database.instance.beginLongLivedReadTransaction()
            Database.instance.setChangeObserver(self, selector: "onDatabaseChange:")
        }.error { err in
            print("err: \(err)")
        }
    }
    
    func onDatabaseChange(notification: NSNotification) {
        let (notifications, connection) = Database.instance.beginLongLivedReadTransaction()
        if notifications.isEmpty {
            return
        }
        if connection.hasChangeForCollection(User.collectionName, inNotifications: notifications) {
            print("users changed")
        }
        if let key = user.key {
            if connection.hasChangeForKey(key, inCollection: User.collectionName, inNotifications: notifications) {
                print("user changed: \(user.email)")
            }
        }
    }
}

