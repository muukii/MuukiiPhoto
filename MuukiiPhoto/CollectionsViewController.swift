//
//  CollectionsViewController.swift
//  PhotoKitTest
//
//  Created by Muukii on 9/20/14.
//  Copyright (c) 2014 Muukii. All rights reserved.
//

import UIKit
import Photos

class CollectionsViewController: UIViewController,PHPhotoLibraryChangeObserver,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView!
    private var collectionsFetchResults: NSArray?
    private var imageManager: PHImageManager = PHImageManager()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure()
    }

    private func configure() {
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchCollections()
    }

    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(nil)
    }


    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange!) {
        /*
        dispatch_async(dispatch_get_main_queue(), ^{

        NSMutableArray *updatedCollectionsFetchResults = nil;

        for (PHFetchResult *collectionsFetchResult in self.collectionsFetchResults) {
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
        if (changeDetails) {
        if (!updatedCollectionsFetchResults) {
        updatedCollectionsFetchResults = [self.collectionsFetchResults mutableCopy];
        }
        [updatedCollectionsFetchResults replaceObjectAtIndex:[self.collectionsFetchResults indexOfObject:collectionsFetchResult] withObject:[changeDetails fetchResultAfterChanges]];
        }
        }

        if (updatedCollectionsFetchResults) {
        self.collectionsFetchResults = updatedCollectionsFetchResults;
        [self.tableView reloadData];
        }

        });

        */
        dispatch_async(dispatch_get_main_queue(), { () -> Void in

            if let _collectionsFetchResults = self.collectionsFetchResults {
                var updatedCollectionsFetchResults : NSMutableArray = _collectionsFetchResults.mutableCopy() as NSMutableArray

                if let collectionsFetchResults = self.collectionsFetchResults {
                    for collectionsFetchResult in collectionsFetchResults{
                        let changeDetails: PHFetchResultChangeDetails? = changeInstance.changeDetailsForFetchResult(collectionsFetchResult as PHFetchResult)

                        if let _changeDetails = changeDetails {
                            updatedCollectionsFetchResults.replaceObjectAtIndex(_collectionsFetchResults.indexOfObject(collectionsFetchResult), withObject: _changeDetails.fetchResultAfterChanges)
                        }

                        self.collectionsFetchResults = updatedCollectionsFetchResults
                        self.tableView.reloadData()
                    }
                }
            }
        })

    }

    private func fetchCollections() {
        func fetch() {
            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.Any, options: nil)
            
            let albumCloudShared: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumCloudShared, options: nil)

            let topLevelUserCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
            

            self.collectionsFetchResults = [smartAlbums,topLevelUserCollections,albumCloudShared]

            self.tableView.reloadData()
        }

        let fetchClosure :((Void) -> Void) =  {
            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.Any, options: nil)

            let albumCloudShared: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumImported, options: nil)
            let albumCloudShared2: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumCloudShared, options: nil)

            let topLevelUserCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
            
            let moment : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Moment, subtype: PHAssetCollectionSubtype.SmartAlbumFavorites, options: nil)

            self.collectionsFetchResults = [smartAlbums,topLevelUserCollections,albumCloudShared2,moment]
            
            self.tableView.reloadData()
        }

        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            fetchClosure()
        } else if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.NotDetermined{
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                fetchClosure()
            })
        } else {
            // Not Authorized!
        }
    }


    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + (self.collectionsFetchResults?.count ?? 0)
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0

        if section == 0 {
            numberOfRows = 1 // 'All Photos' section
        } else {
            let fetchResult: PHFetchResult? = self.collectionsFetchResults?[section - 1] as? PHFetchResult ?? nil
            numberOfRows = fetchResult?.count ?? 0
        }
        return numberOfRows
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CollectionCell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CollectionCell), forIndexPath: indexPath) as CollectionCell

        if indexPath.section == 0 {
            cell.textLabel?.text = "カメラロール"
            
            // 要　最適化
            let options = PHFetchOptions()
            options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.includeHiddenAssets = false
            options.wantsIncrementalChangeDetails = false
            let fetchResult: PHFetchResult? = PHAsset.fetchAssetsWithOptions(options)
            if let asset: PHAsset = fetchResult?[0] as? PHAsset {
                self.imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(40,40), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (result, info) -> Void in
                    cell.myImageView.image = result
                })
            }
            
            println("カメラロール \(fetchResult)")
        } else {
            let fetchResult: PHFetchResult? = self.collectionsFetchResults?[indexPath.section - 1] as? PHFetchResult ?? nil
            let collection: PHCollection? = fetchResult?[indexPath.row] as? PHCollection ?? nil
            let localizedTitle: String? = collection?.localizedTitle

            // 要　最適化
            if let collection = collection {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                options.includeHiddenAssets = false
                options.wantsIncrementalChangeDetails = false
                

                let assetsFetchResult: PHFetchResult? = PHAsset.fetchAssetsInAssetCollection(collection as PHAssetCollection, options: options)
                
                var count: String? = "\(assetsFetchResult?.count)"
                cell.textLabel?.text = (localizedTitle ?? "") + (count ?? "")
                
                println(assetsFetchResult)
                println(assetsFetchResult?.count)
                if assetsFetchResult?.count > 0 {
                    if let asset: PHAsset = assetsFetchResult?[0] as? PHAsset {
                        self.imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(40,40), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (result, info) -> Void in
                            cell.myImageView.image = result
                            var count: String? = "\(assetsFetchResult?.count)"

                        })
                    }
                }
                
            }
        }
        return cell
    }


    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "MuukiiPhoto", bundle: NSBundle(identifier: "Muukii.MuukiiPhoto"))
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(AssetsGridViewController)) as AssetsGridViewController

        if indexPath.section == 0 {
            let options = PHFetchOptions()
            options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.includeHiddenAssets = false
            options.wantsIncrementalChangeDetails = false
            controller.assetsFetchResults = PHAsset.fetchAssetsWithOptions(options)
        } else {

            let fetchResult = self.collectionsFetchResults?[indexPath.section - 1] as PHFetchResult
            let collection = fetchResult[indexPath.row] as PHCollection
            if collection.isKindOfClass(PHAssetCollection) {
                let options = PHFetchOptions()
                options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
                let assetColleciton = collection as PHAssetCollection
                let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(assetColleciton, options: options)
                controller.assetsFetchResults = assetsFetchResult
                controller.assetCollection = assetColleciton
            }
        }

        self.navigationController?.pushViewController(controller, animated: true)
    }
}
