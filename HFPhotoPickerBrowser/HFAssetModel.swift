//
//  HFAssetModel.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit
import Photos
enum HFAssetModelMediaType:Int {
    case Photo = 0
    case LivePhoto
    case PhotoGif
    case Video
    case Audio
}
class HFAssetModel: NSObject {
    var asset : PHAsset?
    var type : HFAssetModelMediaType?
    var isSelected : Bool?
    var timeLength : String?
    
    class func modelWithAsset(asset:PHAsset,type:HFAssetModelMediaType,timeLength:String) -> HFAssetModel {
        let model = self.modelWithAsset(asset: asset, type: type)
        model.timeLength = timeLength
        return model
    }
    
    class func modelWithAsset(asset:PHAsset,type:HFAssetModelMediaType) -> HFAssetModel {
        let model = HFAssetModel()
        model.asset = asset
        model.isSelected = false
        model.type = type
        return model
    }
}


class HFAlbumModel: NSObject {
    var result : PHFetchResult<AnyObject>?{
        willSet{
            let allowPickingImage = UserDefaults.standard.object(forKey: "allowPickingImage") as! String == "1"
            let allowPickingVideo = UserDefaults.standard.object(forKey: "allowPickingVideo") as! String == "1"
            HFImageManager.manager.getAssetsFromFetchResult(result: newValue! , allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (models) in
                self.models = models
            }
        }
    }
    var name : String?
    var isCameraRoll : Bool?
    var count = 0
    var selectedCount = 0
    var selectedModels : Array<HFAssetModel>?
    var models : Array<HFAssetModel>?
    
    
}
