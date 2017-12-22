//
//  ViewController.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/28.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,HFImagePickerControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let views = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        views.width = 100
        views.backgroundColor = UIColor.red
        view.addSubview(views)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1*NSEC_PER_SEC))/Double(NSEC_PER_SEC)) {
            self.pushPhoto()
            //code
            
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
      
    }
    func pushPhoto() {
        let vc = HFPhotoPickerController(maxImagesCount: 3, columnNumber: 4, delegate: self)
        self .present(vc, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imagePickerController(picker: HFPhotoPickerController, didFinishPickingPhotos photos: [UIImage], sourceAssets assets: Array<Any>, isSelectOriginalPhoto: Bool) {
        
    }
    func isAssetCanSelect(asset: AnyObject) -> Bool {
        return true
    }
    func isAlbumCanSelect(albumName: String, result: AnyObject) -> Bool {
        return true
    }
}

