//
//  UIViewLayout.swift
//  HFPhotoBrowser
//
//  Created by qhf on 2017/11/29.
//  Copyright © 2017年 qhf. All rights reserved.
//

import UIKit

extension UIView{
    var width:CGFloat{
        set{
            self.frame.size.width = newValue
        }
        get{
            return self.frame.size.width
        }
    }
    var left:CGFloat{
        set{
            self.frame.origin.x = newValue
        }
        get{
            return self.frame.origin.x
        }
    }
    var top:CGFloat{
        set{
            self.frame.origin.y = newValue
        }
        get{
            return self.frame.origin.y
        }
    }
    var height:CGFloat{
        set{
            self.frame.size.height = newValue
        }
        get{
            return self.frame.size.height
        }
    }
    
}
