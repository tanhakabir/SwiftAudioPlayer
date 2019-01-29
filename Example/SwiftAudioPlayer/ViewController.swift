//
//  ViewController.swift
//  SwiftAudioPlayer
//
//  Created by tanhakabir on 01/28/2019.
//  Copyright (c) 2019 tanhakabir. All rights reserved.
//

import UIKit
import SwiftAudioPlayer

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SAPlayer.shared.rate = 1.0
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

