//
//  HFPhotoPickerController.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit

protocol HFImagePickerControllerDelegate {
    
    func imagePickerController(picker:HFPhotoPickerController ,didFinishPickingPhotos photos:[UIImage],sourceAssets assets:Array<Any>,isSelectOriginalPhoto:Bool ) -> Void
    
    func isAlbumCanSelect(albumName:String,result:AnyObject) -> Bool
    
    func isAssetCanSelect(asset:AnyObject) -> Bool 
}

class HFPhotoPickerController: UINavigationController {
    var _pushPhotoPickerVc = false
    var showSelectBtn = false
    var allowCrop = false
    var selectedModels : Array<HFAssetModel>?
    var allowPickingOriginalPhoto = false
    var allowPickingVideo = false{
        willSet{
            if newValue {
                UserDefaults.standard.set("1", forKey: "allowPickingVideo")
            }else{
                UserDefaults.standard.set("0", forKey: "allowPickingVideo")
            }
        }
    }
    var allowPickingImage = false{
        willSet{
            if newValue {
                UserDefaults.standard.set("1", forKey: "allowPickingImage")
            }else{
                 UserDefaults.standard.set("0", forKey: "allowPickingImage")
            }
        }
    }
    var allowTakePicture = false
    var sortAscendingByModificationDate = false
    var autoDismiss = false
    var didPushPhotoPickerVc = false
    var pushPhotoPickerVc = false
    
    var pickerDelegate : HFImagePickerControllerDelegate?{
        willSet{
            HFImageManager.manager.pickerDelegate = newValue
        }
    }
    
    var maxImagesCount : NSInteger = 0{
        willSet{
            if newValue > 1{
                showSelectBtn = true
                allowCrop = false
            }
        }
    }
    var columnNumber :NSInteger = 0 {
        didSet{
            if columnNumber <= 2{
                columnNumber = 2
            }else if columnNumber >= 6 {
                columnNumber = 6
            }
            let albumPickerVc:HFAlbumPikerController = self.childViewControllers.first as! HFAlbumPikerController
            albumPickerVc.columnNumber = columnNumber
            HFImageManager.manager.columnNumber = columnNumber
            
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
    }
    func setMaxImagesCount(count:NSInteger,delegate:HFImagePickerControllerDelegate,number:NSInteger) {
        
    }
    convenience init(maxImagesCount:NSInteger,delegate:HFImagePickerControllerDelegate) {

        self.init(maxImagesCount: maxImagesCount, columnNumber: 4, delegate: delegate, pushPhotoPickerVc: true)
    }
    
    convenience init(maxImagesCount:NSInteger,columnNumber:NSInteger,delegate:HFImagePickerControllerDelegate) {
       self.init(maxImagesCount: maxImagesCount, columnNumber: columnNumber, delegate: delegate, pushPhotoPickerVc: true)
       
    }
    init(maxImagesCount:NSInteger,columnNumber:NSInteger,delegate:HFImagePickerControllerDelegate,pushPhotoPickerVc:Bool) {
        let albumPickerVc =   HFAlbumPikerController()
        
        albumPickerVc.columnNumber = columnNumber
        super.init(rootViewController: albumPickerVc)
        defer {
            self.pushPhotoPickerVc = pushPhotoPickerVc
            self.maxImagesCount = maxImagesCount
            self.pickerDelegate = delegate
            self.columnNumber = columnNumber
            self.selectedModels = Array()
            self.allowPickingOriginalPhoto = true
            self.allowPickingVideo = true
            self.allowPickingImage = true
            self.allowTakePicture = true
            self.sortAscendingByModificationDate = true
            self.autoDismiss = true
            
            if !HFImageManager.manager.authorizationStatusAuthorized() {
                
            }else{
                self.pushPhotoPickerViewC()
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pushPhotoPickerViewC(){
        didPushPhotoPickerVc = false
        if !didPushPhotoPickerVc&&pushPhotoPickerVc {
            let photoPickerVc = HFAlbumPhotoViewController()
            photoPickerVc.isFirstAppear = true
            photoPickerVc.columnNumber = self.columnNumber
            HFImageManager.manager.getCameraRollAlbum(allowPickingVideo: self.allowPickingVideo, allowPickingImage: self.allowPickingImage, completion: { (model) in
                photoPickerVc.model = model
                self.pushViewController(photoPickerVc, animated: true)
                self.didPushPhotoPickerVc = true
            })
        }
        let vc = self.visibleViewController
        if (vc?.isKind(of: HFAlbumPikerController.self))! {
            (vc as! HFAlbumPikerController).configTableView()
        }
    }

}

class HFAlbumPikerController: UIViewController ,UITableViewDelegate,UITableViewDataSource{
    var columnNumber = 0
    var albumArr :Array<HFAlbumModel>?
    var tableView:UITableView?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView?.frame = CGRect(x: 0, y: (self.navigationController?.navigationBar.height)!, width: self.view.width, height: self.view.height-(self.navigationController?.navigationBar.height)!)
    }
    func configTableView() {
        DispatchQueue.global().async {
            let imagePickerVc = self.navigationController as! HFPhotoPickerController
            HFImageManager.manager.getAllAlbums(allowPickingVideo: imagePickerVc.allowPickingVideo, allowPickingImage: imagePickerVc.allowPickingImage, completion: { (models:Array<HFAlbumModel>) in
                self.albumArr = models
                for model in models{
                    model.selectedModels = imagePickerVc.selectedModels
                }
            })
            DispatchQueue.main.async {
                if self.tableView == nil{
                    
                    self.tableView = UITableView(frame: CGRect(x: 0, y: 64, width: self.view.width, height: self.view.height-64), style: UITableViewStyle.plain)
                    self.tableView!.rowHeight = 70
                    self.tableView!.tableFooterView = UIView()
                    self.tableView!.dataSource = self
                    self.tableView!.delegate = self
                    self.tableView!.register(HFAlbumCell.self, forCellReuseIdentifier: "albumCell")
                    self.view.addSubview(self.tableView!)
                }else{
                    self.tableView!.reloadData()
                }
            }
        }
    }
    
}

extension HFAlbumPikerController{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:HFAlbumCell = tableView.dequeueReusableCell(withIdentifier: "albumCell") as! HFAlbumCell
      //  let imagePickerVc  =  (self.navigationController) as! HFPhotoPickerController
        cell.selectedCountButton?.backgroundColor = UIColor.yellow
        cell.model = albumArr?[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.albumArr?.count)!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photoPickerVc = HFAlbumPhotoViewController()
        photoPickerVc.columnNumber  = self.columnNumber
        let model  = albumArr![indexPath.row]
        photoPickerVc.model = model;
        self.navigationController?.pushViewController(photoPickerVc, animated: true)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

class HFAlbumCell: UITableViewCell {
    var model : HFAlbumModel?{
        willSet{
            self.textLabel?.text = newValue!.name
            HFImageManager.manager.getPostImageWithAlbumModel(model: newValue! ) { (postImage) in
                self.imageView?.image = postImage
            }
        }
    }
    override func layoutSubviews() {
        self.imageView?.frame = CGRect(x: 10, y: 0, width: self.height, height: self.height)
        self.textLabel?.frame = CGRect(x: self.height+10+5, y: 0, width: self.width-self.height-10-5, height: self.height)
    }
    
    var selectedCountButton : UIButton?
    
    
}
