//
//  CSPhotoViewController.swift
//  PhotoAction
//
//  Created by liwei on 2017/2/6.
//  Copyright © 2017年 liwei. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "CSPhotosCell"

enum CSAssetLayoutStyle {
    case photos //照片模式
    case album  //相册模式
    
    private func itemSize(inBoundingSize size: CGSize) -> (itemSize: CGSize, lineSpacing: Int) {
        var length = 0
        let w = Int(size.width)
        var spacing = 1
        for i in 1...3 {
            for n in 4...8 {
                let x = w - ((n-1) * i)
                if x % n == 0 && (x/n) > length {
                    length = x/n
                    spacing = i
                }
            }
        }
        
        return (CGSize(width: length, height: length), spacing)
    }
    
    func recalculate(layout: UICollectionViewFlowLayout, inBoundingSize size: CGSize) {
        switch self {
        case .photos:
            layout.minimumLineSpacing = 1
            layout.minimumInteritemSpacing = 1
            layout.sectionInset = UIEdgeInsets.zero
            let itemInfo = self.itemSize(inBoundingSize: size)
            layout.minimumLineSpacing = CGFloat(itemInfo.lineSpacing)
            layout.itemSize = itemInfo.itemSize
        case .album:
            layout.minimumLineSpacing = 2
            layout.minimumInteritemSpacing = 1
            layout.sectionInset = UIEdgeInsets(top: 1, left: 6, bottom: 0, right: 6)
            layout.scrollDirection = .vertical;
            layout.itemSize = CGSize(width: (Int(size.width)-20)/3, height: (Int(size.width)-20)/3)
        }
    }
}

typealias SelectedPhotosBlock = (_ photos: Array<AnyObject>) -> Void

class CSAssetViewController: UICollectionViewController {
    
    var callBackPhotos: SelectedPhotosBlock?
    
    var showNilAlbum: Bool!
    var showBackBarButton: Bool!
    
    let layoutStyle: CSAssetLayoutStyle

    private var cancelItemButton: UIBarButtonItem!
    private var backItemButton: UIBarButtonItem!
    private var doneItemButton: UIBarButtonItem!
    
    private var fetchResult: PHFetchResult<PHAsset>!
    private var imageManager: PHCachingImageManager!
    private var queue: DispatchQueue!
    private var assetSize: CGSize = CGSize.zero
    private var transitioningAsset: PHAsset?
    private var sizeTransitionIndexPath: IndexPath?
    
    private var dataList: NSMutableArray!
    private var selectedPhotos: NSMutableArray!
    
    // MARK: - Initializers
    init(layoutStyle: CSAssetLayoutStyle, fetchResult: PHFetchResult<PHAsset>? = nil, imageManager: PHCachingImageManager? = nil) {
       
        self.layoutStyle = layoutStyle
        
        if let imageManager = imageManager {
            self.imageManager = imageManager
        } else {
            self.imageManager = PHCachingImageManager()
        }
        
        queue = DispatchQueue(label: "com.photo.prewarm", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
        
        showNilAlbum = false
        showBackBarButton = false
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    private var flowLayout: UICollectionViewFlowLayout {
        return collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    private func recalculateItemSize(inBoundingSize size: CGSize) {
        layoutStyle.recalculate(layout: flowLayout, inBoundingSize: size)
        let itemSize = flowLayout.itemSize
        let scale = UIScreen.main.scale
        assetSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale);
    }

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.view.clipsToBounds = true

        if let collectionView = self.collectionView {
            collectionView.register(AssetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView.backgroundColor = UIColor.clear
        }
        
        getDataList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        cancelItemButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelItemAction))
        backItemButton = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(backItemAction))
        doneItemButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneItemAction))

        if showBackBarButton == false {
            self.navigationItem.leftBarButtonItem = cancelItemButton
        }else {
            self.navigationItem.leftBarButtonItem = backItemButton
            self.navigationItem.rightBarButtonItem = doneItemButton
            doneItemButton.isEnabled = false
        }
        
        recalculateItemSize(inBoundingSize: self.view.bounds.size)
        
        switch layoutStyle {
        case .photos:
            title = "Photos"
            if showBackBarButton == false {
                self.navigationItem.leftBarButtonItem = cancelItemButton
                self.navigationItem.rightBarButtonItem = doneItemButton
                doneItemButton.isEnabled = false
            }else {
                self.navigationItem.leftBarButtonItem = backItemButton
                self.navigationItem.rightBarButtonItem = doneItemButton
                doneItemButton.isEnabled = false
            }
            
        case .album:
            title = "Album"
            self.navigationItem.leftBarButtonItem = cancelItemButton
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        recalculateItemSize(inBoundingSize: size)
        
        if view.window == nil {
            view.frame = CGRect(origin: view.frame.origin, size: size)
            view.layoutIfNeeded()
        } else {
//            let indexPath = self.collectionView?.indexPathsForVisibleItems.last
            coordinator.animate(alongsideTransition: { ctx in
                self.collectionView?.layoutIfNeeded()
            }, completion: { _ in
//                if self.layoutStyle == .oneUp, let indexPath = indexPath {
//                    self.collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
//                }
            })
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - get data list
    private func iterationFetchResult(result: PHFetchResult<PHAssetCollection>) -> Void {
        if result.count > 0 {
            for idx in 0...result.count-1 {
                let collection = result.object(at: idx)
                if showNilAlbum == true {
                    dataList.add(collection)
                }else {
                    let fr = PHAsset.fetchAssets(in: collection, options: nil)
                    if fr.count > 0 {
                        dataList.add(collection)
                    }
                }
            }
        }
    }
    
    private func getDataList() -> Void {
        
        dataList = NSMutableArray()
        dataList.add(UIImage.init(named: "cs_camera")!)
        
        selectedPhotos = NSMutableArray()
        
        switch layoutStyle {
            
        case .album:
            let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            let smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
            
            //自定义相册
            self.iterationFetchResult(result: albumResult)
            
            //智能相册
            self.iterationFetchResult(result: smartAlbumResult)
            
        case .photos:
            if let fetchResult = fetchResult {
                self.fetchResult = fetchResult
            } else {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                self.fetchResult = PHAsset.fetchAssets(with: options)
                for idx in 0...fetchResult.count-1 {
                    dataList.add(fetchResult.object(at: idx) as PHAsset)
                }
            }
        }
    }
    
    // MARK: - button action
    func cancelItemAction() -> Void {
        self.dismiss(animated: true, completion: nil)
    }
    
    func backItemAction() -> Void {
        self.navigationController?.popViewController(animated: true)
    }
    
    func doneItemAction() -> Void {
        //print("selected photos = \(selectedPhotos)")
        
        let tempPhotos = NSMutableArray()

        for idx in 0...selectedPhotos.count-1 {
            let data = selectedPhotos[idx] as! Data
            let image = UIImage(data: data)
            tempPhotos.add(image!)
        }
        
        self.dismiss(animated: true, completion: nil)
        
        if callBackPhotos != nil {
            return callBackPhotos!(tempPhotos as Array)
        }
    }

    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AssetCell

        let item = dataList[indexPath.row] as AnyObject
        
        if item.isKind(of: UIImage.classForCoder()) {
            let img = item as! UIImage
            cell.imageView.image = img
            cell.titleView.isHidden = true
            cell.titleLabel.isHidden = true
        }
        if item.isKind(of: PHAssetCollection.classForCoder()) {
            let collection = item as! PHAssetCollection
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
            let fr = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            if fr.count > 0 {
                let asset = fr.object(at: 0)
                cell.assetIdentifier = asset.localIdentifier
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isNetworkAccessAllowed = true
                
                self.imageManager.requestImage(for: asset, targetSize: self.assetSize, contentMode: .aspectFit, options: options) { (result, info) in
                    if (cell.assetIdentifier == asset.localIdentifier) {
                        cell.imageView.image = result
                    }
                }
            }else {
                cell.imageView.backgroundColor = UIColor.init(colorLiteralRed: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            }
            
            let localizedTitle = collection.localizedTitle! as String
            cell.titleLabel.text = localizedTitle
        }
        if item.isKind(of: PHAsset.classForCoder()) {
            cell.titleView.isHidden = true
            cell.titleLabel.isHidden = true
            
            let asset = item as! PHAsset
            cell.assetIdentifier = asset.localIdentifier
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            
            self.imageManager.requestImage(for: asset, targetSize: self.assetSize, contentMode: .aspectFit, options: options) { (result, info) in
                if (cell.assetIdentifier == asset.localIdentifier) {
                    cell.imageView.image = result
                }
            }
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let item = dataList[indexPath.row] as AnyObject
        if item.isKind(of: UIImage.classForCoder()) {
            
        }
        if item.isKind(of: PHAssetCollection.classForCoder()) {
            let collection = item as! PHAssetCollection
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
            let fr = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            if fr.count > 0 {
                
                let photosController = CSAssetViewController.init(layoutStyle: .photos)
                photosController.showBackBarButton = true
                
                let mutableArray = NSMutableArray()
                for idx in 0...fr.count-1 {
                    mutableArray.add(fr.object(at: idx) as PHAsset)
                }
                photosController.dataList = mutableArray
                
                self.navigationController?.pushViewController(photosController, animated: true)
            }
        }
        if item.isKind(of: PHAsset.classForCoder()) {
            let cell = collectionView.cellForItem(at: indexPath)  as! AssetCell
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            
            self.imageManager.requestImageData(for: item as! PHAsset, options: options, resultHandler: { (data, string, io, any) in
                let image = UIImage(data: data!)
                if self.selectedPhotos.contains(data!) {
                    self.selectedPhotos.remove(data!)
                    cell.setBrulView(select: false)
                }else {
                    self.selectedPhotos.add(data!)
                    cell.setBrulView(select: true)
                }
                
                if self.selectedPhotos.count == 0 {
                    self.doneItemButton.isEnabled = false
                }else {
                    self.doneItemButton.isEnabled = true
                }
            })
            
            
        }
    }
}

