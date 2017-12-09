//
//  HFImageCell.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit
import Photos

class HFImageCell: UICollectionViewCell {
  
    var representedAssetIdentifier : String?
    var imageRequestID:Int32 = 0
    lazy var selectPhotoButton:UIButton = {
       let selectPhotoButton = UIButton()
        selectPhotoButton.addTarget(self, action: #selector(selectPhotoButtonClick(sender:)), for: .touchUpInside)
        return selectPhotoButton
    }()
    var didSelectPhotoBlock : ((Bool)->())?
    
    var bigImageRequestID:Int32 = 0
    
    var selectImage : UIImageView = {
       let image = UIImageView()
        image.isUserInteractionEnabled = true
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
         self.contentView.addSubview(self.imagePhoto)
         self.contentView.addSubview(self.selectImage)
        self.contentView.addSubview(self.selectPhotoButton)
       
       
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var model : HFAssetModel?{
        willSet{
            representedAssetIdentifier = HFImageManager.manager.getAssetIdentifier(asset: (newValue?.asset)!)
            let imageRequestID = HFImageManager.manager.getPhotoWithAsset(asset: (newValue?.asset)!, photoWidth: self.width, completion: { (photo, info, isDegraded) in
                
                self.imagePhoto.image = photo
                if !isDegraded{
                    self.imageRequestID = 0
                }
            }, progressHandler: nil, networkAccessAllowed: false)
            if imageRequestID > 0 && self.imageRequestID > 0 && imageRequestID != self.imageRequestID {
                PHImageManager.default().cancelImageRequest(self.imageRequestID)
            }
            self.imageRequestID = imageRequestID
            self.selectPhotoButton.isSelected = (newValue?.isSelected)!
             self.selectImage.image = self.selectPhotoButton.isSelected ?  UIImage(contentsOfFile: Bundle.imagePickerBundle(name: "photo_sel_photoPickerVc"))  :   UIImage(contentsOfFile: Bundle.imagePickerBundle(name: "photo_def_photoPickerVc"))
            
        }
        didSet{
            if (model?.isSelected)! {
                self.fetchBigImage()
            }
        }
        
        
        
    }

    @objc func selectPhotoButtonClick(sender:UIButton)  {
        if self.didSelectPhotoBlock != nil {
            self.didSelectPhotoBlock!(sender.isSelected)
        }
       
        self.selectImage.image = self.selectPhotoButton.isSelected ?  UIImage(contentsOfFile: Bundle.imagePickerBundle(name: "photo_sel_photoPickerVc"))  :   UIImage(contentsOfFile: Bundle.imagePickerBundle(name: "photo_def_photoPickerVc"))
        if sender.isSelected {
            self.fetchBigImage()
        }else{
            if self.bigImageRequestID > 0{
                PHImageManager.default().cancelImageRequest(self.bigImageRequestID)
            }
        }
    }
    
    func fetchBigImage() {
        self.bigImageRequestID = HFImageManager.manager.getPhotoWithAsset(asset: (self.model?.asset)!, completion: { (photo, info, isDegraded) in
            
        }, progressHandler: { (progress, error, stop, info) in
            if (self.model?.isSelected)! {
                
            }
        }, networkAccessAllowed: true)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.selectPhotoButton.frame = CGRect(x: self.width-44, y: 0, width: 44, height: 44)
        self.selectImage.frame = CGRect(x: self.width-22, y: 0, width: 22, height: 22)
        self.imagePhoto.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
    }
    lazy var imagePhoto :UIImageView = {
        let image = UIImageView(frame:  CGRect(x: 0, y: 0, width: self.width, height: self.height))
        return image
    }()
    
}

class HFAssetCameraCell: UICollectionViewCell {
    
}

