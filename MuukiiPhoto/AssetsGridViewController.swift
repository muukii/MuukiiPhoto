//
//  AssetsGridViewController.swift
//  PhotoKitTest
//
//  Created by Muukii on 9/20/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//

import UIKit
import Photos


private func * (left: CGSize,right: CGFloat) -> CGSize {
    return CGSizeMake(left.width * right, left.height * right)
}

class AssetsGridViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    class AssetsForDay :NSObject {
        var date: NSDate?
        var assets: NSArray?
    }


    var assetsFetchResults: PHFetchResult?
    var assetCollection: PHAssetCollection?

    var devidedAssetsFetchResults: NSArray?

    @IBOutlet private weak var collectionView: UICollectionView!
    private var imageManager: PHCachingImageManager = PHCachingImageManager()
    private var AssetGridThumbnailSize: CGSize = CGSizeZero
    private var previousPreheatRect: CGRect = CGRectZero


    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure()
//        self.resetCachedAssets()
    }

    private func configure() {
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        self.devideByDate()
    }

    private func configureView() {

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillLayoutSubviews() {
        let layout: UICollectionViewFlowLayout = self.collectionView.collectionViewLayout as UICollectionViewFlowLayout

        let sizeLength = CGRectGetWidth(self.collectionView.bounds) / 4
        layout.itemSize = CGSizeMake(sizeLength,sizeLength)
//        layout.estimatedItemSize = CGSizeMake(sizeLength, sizeLength)
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 35)

        let scale: CGFloat = UIScreen.mainScreen().scale
        let cellSize: CGSize = (self.collectionView.collectionViewLayout as UICollectionViewFlowLayout).itemSize
        self.AssetGridThumbnailSize = cellSize * scale
    }

    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(nil)
    }

    func devideByDate() {
        var currentDate: NSDate?
        var currentAssets: NSMutableArray = NSMutableArray()

        var deviedAssets: NSMutableArray = NSMutableArray()

        self.assetsFetchResults?.enumerateObjectsUsingBlock({ (asset, index, stop) -> Void in
            if let asset: PHAsset = asset as? PHAsset {
                if let dateWithOutTime = self.dateWithOutTime(asset.creationDate) {
                    if currentDate == nil {
                        currentDate = dateWithOutTime
                        
                        let assetsForDay: AssetsForDay = AssetsForDay()
                        assetsForDay.assets = currentAssets
                        assetsForDay.date = currentDate
                        deviedAssets.addObject(assetsForDay)
                    }

                    if self.assetsFetchResults?.count == index + 1 || currentDate != dateWithOutTime   {
                        println("AssetsForDay新規 \(currentDate)")
                        
                        currentAssets = NSMutableArray()
                        currentDate = dateWithOutTime

                        let assetsForDay: AssetsForDay = AssetsForDay()
                        assetsForDay.assets = currentAssets
                        assetsForDay.date = currentDate

                        deviedAssets.addObject(assetsForDay)
                        

                    } else {
                    }

                    println("写真 \(asset.creationDate) index \(index) assets:\(self.assetsFetchResults?.count)")
                    currentAssets.addObject(asset)
                    
                } else {
                    fatalError("Date is Null")
                }
            }
        })
        self.devidedAssetsFetchResults = deviedAssets.copy() as? NSArray
        println("\(self.devidedAssetsFetchResults?.count)")
    }

    private func assetByIndexPath(indexPath: NSIndexPath) -> PHAsset? {
        if let devidedAssetsFetchResults = self.devidedAssetsFetchResults {
            if let assetsForDay: AssetsForDay = self.devidedAssetsFetchResults?[indexPath.section] as? AssetsForDay {
                let asset: PHAsset = assetsForDay.assets?[indexPath.item] as PHAsset
                return asset
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    private func dateWithOutTime(date: NSDate) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let units: NSCalendarUnit = NSCalendarUnit.YearCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.DayCalendarUnit
        let comp: NSDateComponents = calendar.components(units, fromDate: date)
        return calendar.dateFromComponents(comp)
    }

    // MARK: - UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.devidedAssetsFetchResults?.count ?? 0
    }

    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let assetsForDay: AssetsForDay? = self.devidedAssetsFetchResults?[section] as? AssetsForDay
        return assetsForDay?.assets?.count ?? 0
    }
    
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(AssetsGridCell), forIndexPath: indexPath) as AssetsGridCell

        let currentTag = cell.tag + 1
        cell.tag = currentTag

        if let asset = self.assetByIndexPath(indexPath) {
            self.imageManager.requestImageForAsset(asset, targetSize: self.AssetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (result, info) -> Void in
                if cell.tag == currentTag {
                    cell.imageView.image = result
                }
            })
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let asset: PHAsset = self.assetByIndexPath(indexPath) {
            println(asset)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: NSStringFromClass(AssetsGridSectionView), forIndexPath: indexPath) as AssetsGridSectionView
            if let assetsForDay: AssetsForDay = self.devidedAssetsFetchResults?[indexPath.section] as? AssetsForDay {
                view.date = assetsForDay.date
            }
            return view
        } else {
            return UICollectionReusableView()
        }
    }


    /*

    private func assetsAtIndexPaths(indexPahts: NSArray) -> NSArray?{
    if indexPahts.count == 0 {
    return nil
    } else {
    let assets = NSMutableArray(capacity: indexPahts.count)
    for indexPath in indexPahts {
    if let asset: PHAsset = self.assetsFetchResults?[indexPath.item] as? PHAsset {
    assets.addObject(asset)
    }
    }
    return assets
    }
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //create cache
        self.updateCachedAssets()
    }

    private func resetCachedAssets() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRectZero
    }
    private func updateCachedAssets() {

        let isViewVisible: Bool = self.isViewLoaded() && self.view.window != nil
        if !isViewVisible {
            return
        }
        var preheatRect = self.collectionView.bounds
        preheatRect = CGRectInset(preheatRect, 0, -0.5 * CGRectGetHeight(preheatRect))

        let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect))
        if delta > CGRectGetHeight(self.collectionView.bounds) / 3.0 {
            let addedIndexPaths: NSMutableArray = NSMutableArray()
            let removedIndexPaths: NSMutableArray = NSMutableArray()

            self.computeDifferenceBetweenRect(self.previousPreheatRect, newRect: preheatRect, removedHandler: { (removedRect) -> Void in
                let indexPaths: NSArray? = self.collectionView.indexPathsForElements(inRect: removedRect)
                if let indexPaths = indexPaths {
                    removedIndexPaths.addObjectsFromArray(indexPaths)
                }
            }, addedHandler: { (addedRect) -> Void in
                let indexPaths: NSArray? = self.collectionView.indexPathsForElements(inRect: addedRect)
                if let indexPaths = indexPaths {
                    addedIndexPaths.addObjectsFromArray(indexPaths)
                }
            })

            let assetsToStartCaching: NSArray? = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching: NSArray? = self.assetsAtIndexPaths(removedIndexPaths);



            self.imageManager.startCachingImagesForAssets(assetsToStartCaching, targetSize: self.AssetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil)
            self.imageManager.stopCachingImagesForAssets(assetsToStopCaching, targetSize: self.AssetGridThumbnailSize, contentMode: PHImageContentMode.AspectFill, options: nil)

            self.previousPreheatRect = preheatRect

        }
    }


    private func computeDifferenceBetweenRect(oldRect: CGRect ,newRect: CGRect, removedHandler: ((removedRect: CGRect) -> Void), addedHandler: ((addedRect: CGRect) -> Void)) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY: CGFloat = CGRectGetMaxX(oldRect)
            let oldMinY: CGFloat = CGRectGetMinY(oldRect)

            let newMaxY: CGFloat = CGRectGetMaxY(newRect)
            let newMinY: CGFloat = CGRectGetMinY(newRect)

            if newMaxY > oldMaxY {
                let rectToAdd: CGRect = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(addedRect: rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd: CGRect = CGRectMake(newRect.origin.y, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(addedRect: rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove: CGRect = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(removedRect: rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(removedRect: rectToRemove)
            }
        } else {
            addedHandler(addedRect: newRect)
            removedHandler(removedRect: oldRect)
        }
    }
*/
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    /*
    - (void)photoLibraryDidChange:(PHChange *)changeInstance
    {
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{

    // check if there are changes to the assets (insertions, deletions, updates)
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
    if (collectionChanges) {

    // get the new fetch result
    self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];

    UICollectionView *collectionView = self.collectionView;

    if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
    // we need to reload all if the incremental diffs are not available
    [collectionView reloadData];

    } else {
    // if we have incremental diffs, tell the collection view to animate insertions and deletions
    [collectionView performBatchUpdates:^{
    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
    if ([removedIndexes count]) {
    [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
    }
    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
    if ([insertedIndexes count]) {
    [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
    }
    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
    if ([changedIndexes count]) {
    [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
    }
    } completion:NULL];
    }

    [self resetCachedAssets];
    }
    });
    }
*/

}

extension NSIndexSet {
    func indexPathsFromIndexes(#section: Int) -> NSArray {
        let indexPaths: NSMutableArray = NSMutableArray(capacity: self.count)
        self.enumerateIndexesUsingBlock { (index, stop) -> Void in
            indexPaths.addObject(NSIndexPath(forItem: index, inSection: section))
        }
        return indexPaths
    }
}

extension UICollectionView {
    func indexPathsForElements(#inRect: CGRect) -> NSArray?{
        let allLayoutAttributes: NSArray? = self.collectionViewLayout.layoutAttributesForElementsInRect(inRect)
        if let _allLayoutAttributes = allLayoutAttributes {
            if _allLayoutAttributes.count != 0 {
                let indexPaths: NSMutableArray = NSMutableArray(capacity: _allLayoutAttributes.count)
                for layoutAttributes in _allLayoutAttributes {
                    let indexPath: NSIndexPath = (layoutAttributes as UICollectionViewLayoutAttributes).indexPath
                    indexPaths.addObject(indexPath)
                }
                return indexPaths
            }
        }
        return nil
    }
}