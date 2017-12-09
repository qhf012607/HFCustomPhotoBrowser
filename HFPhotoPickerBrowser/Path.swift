//
//  File.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/12/8.
//  Copyright © 2017年 qhf. All rights reserved.
//

import Foundation

extension  Bundle{
    class func imagePickerBundle(name:String) -> String {
        let bundle = Bundle.main.path(forResource: "iamge", ofType: "bundle")
        let path = bundle! + "/" + name
        return path
    }
}
