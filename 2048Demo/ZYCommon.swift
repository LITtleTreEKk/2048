//
//  ZYCommon.swift
//  2048Demo
//
//  Created by wpsd on 2017/3/24.
//  Copyright © 2017年 wpsd. All rights reserved.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

let boardLeftMargin : CGFloat = 50
let margin : CGFloat = 7
let cellRowCount : Int = 4

extension UIColor {
    class func rgbColor(red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(displayP3Red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
    }
}
