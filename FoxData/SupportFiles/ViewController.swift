//
//  ViewController.swift
//  FoxData
//
//  Created by Zach Wang on 2019/1/9.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UIDevice.current.model == "iPad"{
            present(UINavigationController(rootViewController: PadMainSplitController()), animated: true)
        }
        else {
            present(UINavigationController(rootViewController: PhMainOuterController()), animated: true)
        }
    }

}

