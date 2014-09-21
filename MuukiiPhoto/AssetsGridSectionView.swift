//
//  AssetsGridSectionView.swift
//  PhotoKitTest
//
//  Created by Muukii on 9/21/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//

import UIKit

class AssetsGridSectionView: UICollectionReusableView {
    @IBOutlet weak var dateLabel: UILabel!
    var date: NSDate? {
        didSet {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy年M月d日"
            if let date = self.date {
                let str = dateFormatter.stringFromDate(date)
                self.dateLabel.text = str
            }
        }
    }
}
