//
//  MuukiiPhotoPickerController.swift
//  PhotoKitTest
//
//  Created by Muukii on 9/20/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//

import UIKit
import Photos
public class PhotoPickerController: UINavigationController {

    let selectedItems: NSMutableArray? = NSMutableArray()
    var maxNumSelectable : Int = 5
    
    public class func photoPicker() -> PhotoPickerController {
        let storyboard = UIStoryboard(name: "MuukiiPhoto", bundle: NSBundle(identifier: "Muukii.MuukiiPhoto"))
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(PhotoPickerController)) as PhotoPickerController
        return controller
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func addAsset(asset:PHAsset){
        if maxNumSelectable >= self.selectedItems?.count {
            self.selectedItems?.addObject(asset)
            println(self.selectedItems?.count)
            println(asset)
        }
    }
}
