//
//  HFAlbumPhotoViewController.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit
import Photos

class HFAlbumPhotoViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    var isFirstAppear = false
    var columnNumber = 0
    var model : HFAlbumModel?
    private var timer : Timer?
    var layout = UICollectionViewFlowLayout()
    var itemMargin:CGFloat = 5.0
    var showTakePhotoBtn = false
    var shouldScrollToBottom = true
    var AssetGridThumbnailSize : CGSize?
    var models : Array<HFAssetModel>?
    var labnum : UILabel?
    var imagenum : UIImageView?
    var buttondown : UIButton?
    var lineView : UIView?
    lazy var toolbar : UIView = {
        let view = UIView(frame:  CGRect(x: 0, y: self.view.height-44, width: self.view.width, height: 44))
        let button = UIButton(frame: CGRect(x: view.width-44-12, y: 0, width: 64, height: 44))
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(button)
        button.addTarget(self, action: #selector(surebutclick), for: .touchUpInside)
        buttondown = button
        let image = UIImageView(frame: CGRect(x: button.left-30, y: 7, width: 30, height: 30))
        view.addSubview(image)
        imagenum = image
        view.addSubview(image)
        let lab  = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        image.addSubview(lab)
        lab.textAlignment = .center
        view.addSubview(lab)
        let line = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 1))
        line.backgroundColor = UIColor(red:  222 / 255.0, green:  222 / 255.0, blue:  222 / 255.0, alpha:  222 / 255.0)
        view.addSubview(line)
        lineView = line
        return view
    }()
    
    @objc func surebutclick() {
        let imagePickerVc : HFPhotoPickerController = self.navigationController as! HFPhotoPickerController
        var photos = Array<AnyObject>()
        var assets = Array<AnyObject>()
        var infoArr = Array<AnyObject>()
        for i in 0..<imagePickerVc.selectedModels!.count {
            photos.append("1" as AnyObject)
            assets.append("1" as AnyObject)
            infoArr.append("1" as AnyObject)
        }
        for i in 0..<imagePickerVc.selectedModels!.count {
            let model = imagePickerVc.selectedModels![i]
            HFImageManager.manager.getPhotoWithAsset(asset: model.asset!, completion: { (photo, info, isdegraded) in
//                if isdegraded{
//                    return
//                }
                if photo != nil{
                    photos[i] = photo!
                }
                if info != nil{
                    infoArr[i] = info!
                }
                assets[i] = model.asset!
                for item in photos{
                    if item is String{
                        return
                    }
                }
                self.didGetAllPhotos(photos: photos, assets: assets, infoArr: infoArr)
            }, progressHandler: { (progress, error, stop, info) in
                
            }, networkAccessAllowed: true)
        }
        if imagePickerVc.selectedModels!.count<=0 {
            self.didGetAllPhotos(photos: photos, assets: assets, infoArr: infoArr)
        }
    }
    
    func didGetAllPhotos(photos:Array<AnyObject>,assets:Array<AnyObject>,infoArr:Array<AnyObject>) -> Void {
        
         let imagePickerVc : HFPhotoPickerController = self.navigationController as!HFPhotoPickerController
        if imagePickerVc.autoDismiss {
            self.navigationController?.dismiss(animated: true, completion: {
                self.callDelegateMethodWithPhotos(photos: photos as! Array<UIImage>, assets: assets as! Array<PHAsset>, infoArr: infoArr as! Array<NSDictionary>)
            })
        }else{
            self.callDelegateMethodWithPhotos(photos: photos as! Array<UIImage>, assets: assets as! Array<PHAsset>, infoArr: infoArr as! Array<NSDictionary>)
        }
        
    }
    
    func callDelegateMethodWithPhotos(photos:Array<UIImage>,assets:Array<PHAsset>,infoArr:Array<NSDictionary>) -> Void {
        let imagePickerVc : HFPhotoPickerController = self.navigationController as!HFPhotoPickerController
        if imagePickerVc.pickerDelegate != nil {
            imagePickerVc.pickerDelegate?.imagePickerController(picker: imagePickerVc, didFinishPickingPhotos: photos, sourceAssets: assets, isSelectOriginalPhoto:true)
        }
    }
    func scaleImage(image:UIImage,size:CGSize) -> UIImage {
        if image.size.width < size.width {
            return image
        }
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newimage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newimage
    }
    lazy var collectionView : HFCollectionView = {
        let collectionView = HFCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.alwaysBounceHorizontal = false;
        collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
        collectionView.register(HFImageCell.self, forCellWithReuseIdentifier: "imageCell")
        collectionView.register(HFAssetCameraCell.self, forCellWithReuseIdentifier: "AssetCameraCell")
        return collectionView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
      //  self.view.addSubview(self.collectionView)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var scale:CGFloat = 2.0
        if UIScreen.main.bounds.size.width>600 {
            scale = 1.0
        }
        let cellSize = layout.itemSize
        AssetGridThumbnailSize = CGSize(width: cellSize.width*scale, height: cellSize.height*scale)
        if models == nil {
            self .fetchAssetModels()
        }
       
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.toolbar.frame = CGRect(x: 0, y: self.view.height-44, width: self.view.width, height: 44)
        self.buttondown?.frame = CGRect(x: view.width-44-12, y: 0, width: 44, height: 44)
        self.imagenum?.frame =  CGRect(x: (self.buttondown?.left)!-30, y: 7, width: 30, height: 30)
        self.labnum?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
       
        self.lineView?.frame = CGRect(x: 0, y: 0, width: self.view.width, height: 1)
        let itemWH:CGFloat = (self.view.width - CGFloat(self.columnNumber + 1) * CGFloat(itemMargin)) / CGFloat(self.columnNumber);
        layout.itemSize = CGSize(width:itemWH,height:itemWH);
        layout.minimumInteritemSpacing = itemMargin;
        layout.minimumLineSpacing = itemMargin;
        self.collectionView.collectionViewLayout = layout
        self.collectionView.frame = CGRect(x: 0, y: (self.navigationController?.navigationBar.height)!, width: self.view.width, height: self.view.height-(self.navigationController?.navigationBar.height)!-self.toolbar.height)
        self.collectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchAssetModels() {
        let imagePickerVc : HFPhotoPickerController = self.navigationController as! HFPhotoPickerController
        if isFirstAppear {
            
        }
        DispatchQueue.global().async {
            if imagePickerVc.sortAscendingByModificationDate&&self.isFirstAppear{
                HFImageManager.manager.getCameraRollAlbum(allowPickingVideo: imagePickerVc.allowPickingVideo, allowPickingImage: imagePickerVc.allowPickingImage, completion: { (model) in
                    self.model = model
                    self.models = model?.models
                    self.initSubviews()
                })
            }else{
                if self.isFirstAppear || self.showTakePhotoBtn{
                    HFImageManager.manager.getAssetsFromFetchResult(result: (self.model?.result)! , allowPickingVideo: imagePickerVc.allowPickingVideo, allowPickingImage: imagePickerVc.allowPickingImage, completion: { (models) in
                        self.models = models
                        self.initSubviews()
                    })
                }else{
                
                self.models = self.model?.models
                self.initSubviews()
                }
            }
            
        }
    }
    
    func initSubviews() {
        DispatchQueue.main.async {
           // let imagePickerVc = self.navigationController as! HFPhotoPickerController
            self.collectionView.isHidden = true
            self.checkSelectedModels()
            self.configCollectionView()
            self.scrollCollectionViewToBottom()
           //  self.view.addSubview(self.collectionView)
        }
    }
    
    func configCollectionView(){
         let itemWH:CGFloat = (self.view.width - CGFloat(self.columnNumber + 1) * CGFloat(itemMargin)) / CGFloat(self.columnNumber);
        layout.itemSize = CGSize(width:itemWH,height:itemWH);
        layout.minimumInteritemSpacing = itemMargin;
        layout.minimumLineSpacing = itemMargin;
        self.collectionView.collectionViewLayout = layout
        self.collectionView.frame = CGRect(x: 0, y: (self.navigationController?.navigationBar.height)!, width: self.view.width, height: self.view.height-(self.navigationController?.navigationBar.height)!-self.toolbar.height)
            //    self.collectionView.reloadData()

        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.toolbar)
    }
    
    func scrollCollectionViewToBottom() {
        let imagePickerVc = self.navigationController as! HFPhotoPickerController
        if shouldScrollToBottom && models!.count > 0 {
            var item = 0
            if imagePickerVc.sortAscendingByModificationDate{
                item = (self.models?.count)! - 1
                if(showTakePhotoBtn){
                    if imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture{
                        item += 1
                    }
                }
                
            }
            DispatchQueue.main.async {
                
                self.collectionView.scrollToItem(at:  IndexPath(item: item, section: 0) , at: .bottom, animated: false)
                self.shouldScrollToBottom = false
                self.collectionView.isHidden = false
            }
        }else{
            self.collectionView.isHidden = false
        }
        
    }
    
    func checkSelectedModels() {
        for model in models! {
            model.isSelected = false
            var selectedAssets = Array<PHAsset>()
            let ImagePickerVc = self.navigationController as!HFPhotoPickerController
            for modelSelect in ImagePickerVc.selectedModels!{
                selectedAssets.append(modelSelect.asset!)
            }
            if HFImageManager.manager.isAssetsArray(assets: selectedAssets, containAsset: model.asset!){
                model.isSelected = true
            }
        }
    }
    func refreshBottomToolBarStatus() {
         let imagePickerVc = self.navigationController as! HFPhotoPickerController
        self.labnum?.text = "\(String(describing: imagePickerVc.selectedModels?.count))"
    }

}

extension HFAlbumPhotoViewController{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imagePickerVc = self.navigationController as! HFPhotoPickerController
        if (imagePickerVc.sortAscendingByModificationDate && indexPath.row >= (self.models?.count)!)||(!imagePickerVc.sortAscendingByModificationDate && indexPath.row==0 && showTakePhotoBtn){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCameraCell", for: indexPath)
            cell.backgroundColor = UIColor.yellow
            return cell
        }
        let model : HFAssetModel?
        if imagePickerVc.sortAscendingByModificationDate || !showTakePhotoBtn {
            model = models?[indexPath.row]
        }else{
            model = models?[indexPath.row-1]
        }
        let cellPhoto : HFImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! HFImageCell
        cellPhoto.model = model
        cellPhoto.didSelectPhotoBlock = { [weak self] (isSelected)  in
            if let strongSelf = self {
                if isSelected {
                    cellPhoto.selectPhotoButton.isSelected = false
                    model?.isSelected = false
                    let selectedModels = imagePickerVc.selectedModels
                    for model_item in selectedModels!{
                        print(strongSelf)
                        if HFImageManager.manager.getAssetIdentifier(asset: (model?.asset!)!) ==  HFImageManager.manager.getAssetIdentifier(asset: model_item.asset!){
                            let index = selectedModels?.index(of: model_item)
                            imagePickerVc.selectedModels?.remove(at: index!)
                            break
                        }
                    }
                }else{
                    if (imagePickerVc.selectedModels?.count)! < imagePickerVc.maxImagesCount{
                        cellPhoto.selectPhotoButton.isSelected  = true
                        model?.isSelected = true
                        imagePickerVc.selectedModels?.append(model!)
                        self?.refreshBottomToolBarStatus()
                    }
                }
            }
        }
        return cellPhoto
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showTakePhotoBtn {
            let imagePickerVc = self.navigationController as! HFPhotoPickerController
            if imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture{
                return (self.models?.count)! + 1
            }
        }
        return (self.models?.count)!
    }
}

class HFCollectionView: UICollectionView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIControl.self) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}
