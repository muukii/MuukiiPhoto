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
    
    class Album {
        var collection: PHAssetCollection?
        var title: String?
        var numberOfAssets: Int?
        var latestAsset: PHAsset?
    }

    @IBOutlet private weak var tableView: UITableView!
    private var collectionsFetchResults: NSArray?
    
    private var albums: [Album]?
    

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
      

        let fetchClosure :((Void) -> Void) =  {
            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.Any, options: nil)
            
            let topLevelUserCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)

            let albumCloudShared: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: nil)

            self.collectionsFetchResults = [smartAlbums,topLevelUserCollections,albumCloudShared]
            
            let fetchResults: [PHFetchResult] = [smartAlbums, topLevelUserCollections, albumCloudShared]
            
            self.albums = [Album]()
            
            for fetchResult in fetchResults {
                fetchResult.enumerateObjectsUsingBlock({ (collection, index, stop) -> Void in
                    let collection = collection as PHAssetCollection
                    let album = Album()
                    album.collection = collection
                    album.title = collection.localizedTitle
                    
                    let options = PHFetchOptions()
                    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    options.includeHiddenAssets = false
                    options.wantsIncrementalChangeDetails = false
                    
                    let assetsFetchResult: PHFetchResult? = PHAsset.fetchAssetsInAssetCollection(collection as PHAssetCollection, options: options)
                    album.numberOfAssets = assetsFetchResult?.count
                    album.latestAsset = assetsFetchResult?.firstObject as? PHAsset
                    
                    self.albums?.append(album)
                })
            }
            println("Albums : \(self.albums)")
            
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
        // カメラロール　+ アルバム
        return 2
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0

        if section == 0 {
            numberOfRows = 1 // 'All Photos' section
        } else {
            numberOfRows = self.albums?.count ?? 0
        }
        return numberOfRows
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CollectionCell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(CollectionCell), forIndexPath: indexPath) as CollectionCell

        if indexPath.section == 0 {
            cell.textLabel?.text = "カメラロール"
            
            let options = PHFetchOptions()
            options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.includeHiddenAssets = false
            options.wantsIncrementalChangeDetails = false
            let fetchResult: PHFetchResult? = PHAsset.fetchAssetsWithOptions(options)
            if let asset: PHAsset = fetchResult?.firstObject as? PHAsset {
                self.imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(40,40), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (result, info) -> Void in
                    cell.imageView!.image = result
                })
            }
            
        } else {
            let album = self.albums?[indexPath.row]
            cell.textLabel?.text = album?.title
            
            self.imageManager.requestImageForAsset(album?.latestAsset, targetSize: CGSizeMake(30, 30), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info) -> Void in
                cell.imageView!.image = image
            })
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

            let collection = self.albums?[indexPath.row].collection
            if let collection = collection {
                let options = PHFetchOptions()
                options.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)]
                let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: options)
                controller.assetsFetchResults = assetsFetchResult
                controller.assetCollection = collection
            }
        }

        self.navigationController?.pushViewController(controller, animated: true)
    }
}
