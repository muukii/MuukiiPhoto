//
//  AssetsGridCell.swift
//  PhotoKitTest
//
//  Created by Muukii on 9/20/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//

import UIKit

class AssetsGridCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTranslatesAutoresizingMaskIntoConstraints(true)
        self.configure()
    }
    
    private func configure() {
        
        self.contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        if let selectedView = self.selectedView {
            selectedView.hidden = true
            self.addSubview(selectedView)
        }
        
    }
    
    var selectedView: UIView? {
        get {
            if _selectedView == nil {
                _selectedView = UIView()
                var rect:CGRect = self.bounds;
                rect.size.width += 2;
                rect.size.height += 1;
                _selectedView?.frame = rect
                _selectedView?.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.8)
                _selectedView?.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
         
                let checkMark:UIImageView = UIImageView(image: UIImage(named:"imagepicker_check"))
                checkMark.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleRightMargin
                checkMark.frame = CGRectMake(0,0,20,20)
                checkMark.contentMode = UIViewContentMode.ScaleAspectFit
                checkMark.center = self.center
                self.selectedView?.addSubview(checkMark)
            }
            
            return _selectedView
        }
        set {
            _selectedView = newValue
        }
    }
    
    private var _selectedView:UIView?

    override func layoutSubviews() {
        super.layoutSubviews()
        if let selectedView = self.selectedView {
            self.bringSubviewToFront(selectedView)
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected;
        }
        set {
            self.selectedView?.hidden = !newValue
            super.selected = newValue
        }
    }
}
