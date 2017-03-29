//
//  ZYTile.swift
//  2048Demo
//
//  Created by wpsd on 2017/3/24.
//  Copyright © 2017年 wpsd. All rights reserved.
//

import UIKit

class ZYTileCell: UILabel {

    var num : Int?{
        didSet{
            guard let num = num else { return }
            self.text = "\(num)"
            if num == 2 {
                self.backgroundColor = UIColor.rgbColor(red: 238, green: 228, blue: 218)
            }else if num == 4 {
                self.backgroundColor = UIColor.rgbColor(red: 237, green: 220, blue: 200)
            }else if num == 8 {
                self.backgroundColor = UIColor.rgbColor(red: 242, green: 177, blue: 121)
                self.textColor = UIColor.white
            }else if num == 16 {
                self.backgroundColor = UIColor.rgbColor(red: 245, green: 149, blue: 99)
                self.textColor = UIColor.white
            }else if num == 32 {
                self.backgroundColor = UIColor.rgbColor(red: 246, green: 124, blue: 95)
                self.textColor = UIColor.white
            }else if num == 64 {
                self.backgroundColor = UIColor.rgbColor(red: 246, green: 94, blue: 59)
                self.textColor = UIColor.white
            }else {
                self.backgroundColor = UIColor.rgbColor(red: 237, green: 207, blue: 114)
                self.textColor = UIColor.white
            }
        }
    }
    var isCombined = false
    var tilePath : ZYTilePath
    let cellID : Int
    
    init(indexPath: ZYTilePath, cellID : Int) {
        self.tilePath = indexPath
        self.cellID = cellID
        let cellWH = (SCREEN_WIDTH - boardLeftMargin * 2 - margin * CGFloat(cellRowCount + 1)) / CGFloat(cellRowCount)
        let cellX = CGFloat(indexPath.column) * (cellWH + margin) + margin
        let cellY = CGFloat(indexPath.row) * (cellWH + margin) + margin
        super.init(frame: CGRect(x: cellX, y: cellY, width: cellWH, height: cellWH))
        self.font = UIFont.boldSystemFont(ofSize: 25)
        self.backgroundColor = UIColor.clear
        self.textColor = UIColor.rgbColor(red: 119, green: 110, blue: 100)
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        self.textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var description: String {
        return "tilePath:\(tilePath),num:\(num!)"
    }
    
}

class ZYTilePath: NSObject {
    var row : Int
    var column : Int
    init(row : Int, column: Int) {
        self.row = row
        self.column = column
    }
    override var description: String {
        return "row:\(row),column:\(column)"
    }
}
