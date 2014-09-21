//
//  ViewController.swift
//  MuukiiPhotoExample
//
//  Created by Muukii on 9/22/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//


import UIKit
import MuukiiPhoto

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let controller = PhotoPickerController.photoPicker()
        self.presentViewController(controller, animated: true) { () -> Void in

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

