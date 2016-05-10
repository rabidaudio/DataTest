
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
        
        let user = User()
        user.email = "woopee@doo"
//        user.create()
    }
}

