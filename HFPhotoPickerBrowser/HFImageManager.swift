//
//  HFImageManager.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit
import Photos

class HFImageManager: NSObject {
    var sortAscendingByModificationDate = false
    var pickerDelegate : HFImagePickerControllerDelegate?
    var hideWhenCanNotSelect = false
    var HFScreenWidth:CGFloat = 0
    var AssetGridThumbnailSize : CGSize?
    var ScreenScale = 0.0
    var photoPreviewMaxWidth:CGFloat = 600.0
    var shouldFixOrientation = false
    
//    var photoWidth : CGFloat?{
//        willSet{
//            HFScreenWidth = newValue!/CGFloat(2)
//        }
//    }
    
    var columnNumber : NSInteger = 0{
        willSet{
            self.configScreenWidth()
            let margin = 4
            let itemWH = (HFScreenWidth - (2*CGFloat(margin)) - 4)/CGFloat(newValue) - CGFloat(margin)
            AssetGridThumbnailSize = CGSize(width: itemWH*HFScreenWidth, height: itemWH*CGFloat( ScreenScale))
        }
    }
    
    static let manager : HFImageManager = {
        let manager = HFImageManager()
        return manager
    }()
    
    func authorizationStatusAuthorized() -> Bool {
        let status = HFImageManager.authorizationStatus()
        if status == 0 {
            self.requestAuthorizationWithCompletion(completion: nil)
        }
        return status == 3
    }
    
    class func authorizationStatus() -> NSInteger {
        return PHPhotoLibrary.authorizationStatus().rawValue
    }
    
    func configScreenWidth() {
        HFScreenWidth = UIScreen.main.bounds.size.width
        ScreenScale = 2.0
        if (HFScreenWidth > 700) {
            ScreenScale = 1.5;
        }
    }
    
    func requestAuthorizationWithCompletion(completion: (()->())?) -> Void {
        DispatchQueue.global().async {
            PHPhotoLibrary.requestAuthorization({ (status:PHAuthorizationStatus) in
                if (completion != nil){
                DispatchQueue.main.async {
                    completion!()
                }
                }
            })
        }
    }
    func getCameraRollAlbum(allowPickingVideo:Bool,allowPickingImage allow:Bool,completion:((HFAlbumModel?)->())?) -> Void {
        let option = PHFetchOptions()
        var model:HFAlbumModel?
        if (!allowPickingVideo) {
            option.predicate = NSPredicate(format:"mediaType == \(PHAssetMediaType.image)")
        }
        if (!allowPickingVideo) {
            option.predicate = NSPredicate(format:"mediaType == \(PHAssetMediaType.video)")
        }
        if (!sortAscendingByModificationDate) {
            option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: sortAscendingByModificationDate)];
        }
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        for  i  in 0..<smartAlbums.count{
            let collection = smartAlbums.object(at: i)
            if !collection.isKind(of: PHAssetCollection.self){
                continue
            }
            if(self.isCameraRollAlbum(metadata: collection)){
                let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                model = self.modelWithResult(result: fetchResult, name: collection.localizedTitle, isCameraRoll: true)
                if completion   != nil{
                    completion!(model)
                    break
                }
            }
        
        }
        
    }
    func getAllAlbums(allowPickingVideo:Bool,allowPickingImage:Bool,completion:(([HFAlbumModel])->())?) -> Void {
        let albumArr = NSMutableArray()
        let option = PHFetchOptions()
        if (!allowPickingVideo) {
            option.predicate = NSPredicate(format:"mediaType == \(PHAssetMediaType.image)")
        }
        if (!allowPickingImage) {
            option.predicate = NSPredicate(format:"mediaType == \(PHAssetMediaType.video)")
        }
        if (!sortAscendingByModificationDate) {
            option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: sortAscendingByModificationDate)];
        }
        let myPhotoStreamAlbum = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumMyPhotoStream, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: nil)
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumCloudShared, options: nil)
        let allAlbums = [myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
        for object in allAlbums {
            let fetchResult = object as! PHFetchResult<AnyObject>
            for  i  in 0..<fetchResult.count{
                 let collection = fetchResult.object(at: i)
                if (!collection.isKind(of: PHAssetCollection.self) ){
                    continue
                }
                let fetchResult = PHAsset.fetchAssets(in: collection as! PHAssetCollection, options: option)
                if (fetchResult.count < 1) {
                    continue
                }
                if (!(self.pickerDelegate?.isAlbumCanSelect(albumName: collection.localizedTitle, result: fetchResult))!) {
                    continue
                }
    
                if((((collection)as!PHAssetCollection).localizedTitle?.contains("Hidden"))!||((collection)as!PHAssetCollection).localizedTitle=="已隐藏"){
                    continue
                }
                if((((collection)as!PHAssetCollection).localizedTitle?.contains("Deleted"))!||((collection)as!PHAssetCollection).localizedTitle=="最近删除"){
                    continue
                }
                if(self.isCameraRollAlbum(metadata: collection)){
                   albumArr.insert(self.modelWithResult(result: fetchResult, name: collection.localizedTitle, isCameraRoll: true), at: 0)
                }else{
                    albumArr.add(self.modelWithResult(result: fetchResult, name: collection.localizedTitle, isCameraRoll: false))
                }
                
            }
            
            
        }
        if completion   != nil{
            completion!(albumArr as! [HFAlbumModel])
        }
    }
    func getAssetsFromFetchResult(result:PHFetchResult<AnyObject>,allowPickingVideo:Bool,allowPickingImage:Bool,completion:((Array<HFAssetModel>)->())?) -> Void {
        var photoArr = Array<HFAssetModel>()
        
        result.enumerateObjects { (obj, idx, stop) in
            let model = self.assetModelWithAsset(asset: obj, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if model != nil{
                photoArr.append(model!)
            }
        }
        if completion != nil{
            completion!(photoArr)
        }
    }
    
    func getAssetFromFetchResult(result:AnyObject,index:NSInteger,allowPickingVideo:Bool,allowPickingImage:Bool,completion:((HFAssetModel?)->())?) -> Void {
        let fetchResult = result as!PHFetchResult<AnyObject>
        if let asset = fetchResult.object(at: index) as? PHAsset {
            let model = self.assetModelWithAsset(asset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if (completion != nil){
                completion!(model)
            }
            
        }else{
            if (completion != nil){
                completion!(nil)
            }
            return
        }
       
    }
    func modelWithResult(result:AnyObject,name:String? ,isCameraRoll:Bool) -> HFAlbumModel {
        let model = HFAlbumModel()
        model.result = result as? PHFetchResult<AnyObject>;
        model.name = name;
        model.isCameraRoll = isCameraRoll;
        model.count = (result as!PHFetchResult<AnyObject>).count as NSInteger
        return model
    }
    
    func assetModelWithAsset(asset:AnyObject,allowPickingVideo:Bool,allowPickingImage:Bool) -> HFAssetModel? {
        var canSelect = true
        canSelect = (self.pickerDelegate?.isAssetCanSelect(asset: asset))!
        if !canSelect {
             return nil
        }
        let model :HFAssetModel?

        let type = self.getAssetType(asset: asset)
        if !allowPickingVideo&&type==HFAssetModelMediaType.Video {
            return nil
        }
        if !allowPickingImage&&type==HFAssetModelMediaType.Photo {
            return nil
        }
        if !allowPickingImage&&type==HFAssetModelMediaType.PhotoGif {
            return nil
        }
        let phAsset = asset as!PHAsset;
        if self.hideWhenCanNotSelect{
            
        }
        model = HFAssetModel.modelWithAsset(asset: phAsset, type: type)
        return model
    }
    func isPhotoSelectableWithAsset(asset:AnyObject) -> Bool {
      //  let size = self.photoSizeWithAsset(asset: asset)
        return true
    }
    
    func isAssetsArray(assets:Array<PHAsset>,containAsset:PHAsset) -> Bool{
       return assets.contains(containAsset)
    }
    
    func photoSizeWithAsset(asset:AnyObject) -> CGSize {
       
        return  CGSize(width:(asset as!PHAsset).pixelWidth,height:(asset as!PHAsset).pixelHeight)
    }
    func getAssetType(asset:AnyObject) -> HFAssetModelMediaType {
        var type = HFAssetModelMediaType.Photo
        let phAsset = asset as!PHAsset
        if (phAsset.mediaType == PHAssetMediaType.video)   {
            type = HFAssetModelMediaType.Video
        }else if (phAsset.mediaType == PHAssetMediaType.audio) {
            type = HFAssetModelMediaType.Audio
        }else if (phAsset.mediaType == PHAssetMediaType.image) {
            let string = phAsset.value(forKey: "filename")
            if ((string as!String).hasSuffix("GIF")) {
                type = HFAssetModelMediaType.PhotoGif;
            }
        }
        return type
    }
    
    func getAssetIdentifier(asset:PHAsset) -> String {
        return asset.localIdentifier
    }
    
    func isCameraRollAlbum(metadata:AnyObject) -> Bool {
        return false
    }
    func getPostImageWithAlbumModel(model:HFAlbumModel,completion:((UIImage)->())?) -> () {
        var asset = model.result?.lastObject
        if !self.sortAscendingByModificationDate {
            asset = model.result?.firstObject
        }
        _ = HFImageManager.manager.getPhotoWithAsset(asset: asset as! PHAsset, photoWidth: 80) { (photo, info, isDegraded) in
            if completion != nil{
                completion!(photo)
            }
        }
        
    }
    func getPhotoWithAsset(asset:PHAsset,completion:((UIImage,NSDictionary,Bool)->())?) -> Int32 {
        var fullScreenWidth = HFScreenWidth
        if fullScreenWidth > photoPreviewMaxWidth{
            fullScreenWidth = photoPreviewMaxWidth
        }
        return self.getPhotoWithAsset(asset: asset, photoWidth: fullScreenWidth, completion: completion, progressHandler: nil, networkAccessAllowed: true)
    }
    
    func getPhotoWithAsset(asset:PHAsset,photoWidth:CGFloat,completion:((UIImage,NSDictionary,Bool)->())?) -> Int32 {
        return self.getPhotoWithAsset(asset: asset, photoWidth: photoWidth, completion: completion, progressHandler: nil, networkAccessAllowed: true)
    }
    
    func getPhotoWithAsset(asset:PHAsset,completion:((UIImage,NSDictionary,Bool)->())?,progressHandler:((Double,NSError,UnsafeMutablePointer<ObjCBool>,NSDictionary)->())?,networkAccessAllowed:Bool)-> Int32{
        var fullScreenWidth = HFScreenWidth
        if fullScreenWidth > photoPreviewMaxWidth{
            fullScreenWidth = photoPreviewMaxWidth
        }
        return self.getPhotoWithAsset(asset: asset, photoWidth: fullScreenWidth, completion: completion, progressHandler: progressHandler, networkAccessAllowed: networkAccessAllowed)
    }
    func getPhotoWithAsset(asset:PHAsset,photoWidth:CGFloat,completion:((UIImage,NSDictionary,Bool)->())?,progressHandler:((Double,NSError,UnsafeMutablePointer<ObjCBool>,NSDictionary)->())?,networkAccessAllowed:Bool) -> Int32 {
        var imageSize:CGSize?
        if photoWidth<HFScreenWidth && photoWidth<photoPreviewMaxWidth{
            imageSize = AssetGridThumbnailSize
        }else{
            let phAsset =  asset
            let aspectRatio = CGFloat(phAsset.pixelWidth/phAsset.pixelHeight)
            var pixelWidth = photoWidth * CGFloat(ScreenScale) * 1.5
            // 超宽图片
            if aspectRatio > 1.8{
                pixelWidth = pixelWidth * aspectRatio
            }
             // 超高图片
            if aspectRatio < 0.2{
                pixelWidth = pixelWidth * 0.5
            }
            let pixelHeight = pixelWidth / aspectRatio
            imageSize = CGSize(width: pixelWidth, height: pixelHeight)
        }
        var image : UIImage?
        let option = PHImageRequestOptions()
        option.resizeMode = PHImageRequestOptionsResizeMode.fast
        let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imageSize!, contentMode: PHImageContentMode.aspectFill, options: option) { (result:UIImage?, info:Dictionary?) in
            if result != nil{
                image = result
            }
            let downloadFinined = (!(info![PHImageCancelledKey] != nil)) && (!(info![PHImageErrorKey] != nil))
            //
            if( downloadFinined && (result != nil)) {
                image = self.fixOrientation(aImage: image!)
                if completion != nil{
                    completion!(image!,info! as NSDictionary,(info![PHImageResultIsDegradedKey] != nil))
                }
            }
            
            if (info![PHImageResultIsInCloudKey] != nil)&&image==nil&&networkAccessAllowed{
                let options = PHImageRequestOptions()
                options.progressHandler = {
                    (progress,error,stop,info) in
                    DispatchQueue.main.async {
                        if(progressHandler != nil){
                            progressHandler!(progress,error! as NSError,stop,info! as NSDictionary)
                        }
                    }
                }
                options.isNetworkAccessAllowed = true;
                options.resizeMode = PHImageRequestOptionsResizeMode.fast;
                PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    var resultImage = UIImage.init(data: imageData!, scale: 0.1)
                    resultImage = self.scaleImage(image: resultImage!, size: imageSize!)
                    if completion != nil{
                        completion!(resultImage!,info! as NSDictionary,false)
                    }
                })
            }
            
        }
        return imageRequestID
    }
    
    func scaleImage(image:UIImage,size:CGSize) -> UIImage {
        if (image.size.width > size.width) {
            UIGraphicsBeginImageContext(size);
            image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return newImage!;
        } else {
            return image;
        }
    }
    func fixOrientation(aImage:UIImage) -> UIImage {
        if !self.shouldFixOrientation {
            return aImage
        }
        if aImage.imageOrientation == UIImageOrientation.up {
            return aImage
        }
        var transform = CGAffineTransform.identity
        switch aImage.imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
           transform = CGAffineTransform(translationX: aImage.size.width, y: aImage.size.height)
           transform = CGAffineTransform(rotationAngle: .pi)
            break
        case UIImageOrientation.left,UIImageOrientation.leftMirrored:
            transform = CGAffineTransform(translationX: aImage.size.width, y: 0)
            transform = CGAffineTransform(rotationAngle:.pi/2)
            break
        
        case UIImageOrientation.right,UIImageOrientation.rightMirrored:
            transform = CGAffineTransform(translationX: 0, y: aImage.size.height)
            transform = CGAffineTransform(rotationAngle:-.pi/2)
            break
        default:
            break
        }
        switch aImage.imageOrientation {
        case UIImageOrientation.upMirrored,UIImageOrientation.downMirrored:
            transform = CGAffineTransform(translationX: aImage.size.width, y: 0)
            transform = CGAffineTransform(scaleX: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored,UIImageOrientation.rightMirrored:
            transform = CGAffineTransform(translationX: aImage.size.height, y: 0)
            transform = CGAffineTransform(scaleX: -1, y: 1)
            break
        default:
            break
        }
      //  let y = CGImage.bit
        guard let cgImage = aImage.cgImage else {
            return aImage
        }
        guard let ctx = CGContext.init(data: nil, width: Int(aImage.size.width), height: Int(aImage.size.height), bitsPerComponent: Int(cgImage.bitsPerComponent), bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return aImage
        }
        ctx.concatenate(transform)
        switch aImage.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: aImage.size.height, height: aImage.size.width))
            break
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: aImage.size.width, height: aImage.size.height))
            break
        }
        if let cgImg = ctx.makeImage() {
            return UIImage(cgImage: cgImg)
        }
        return aImage
    }
}
