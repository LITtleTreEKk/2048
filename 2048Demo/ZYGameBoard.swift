//
//  ZYGameBoard.swift
//  2048Demo
//
//  Created by wpsd on 2017/3/24.
//  Copyright © 2017年 wpsd. All rights reserved.
//

import UIKit

class ZYGameBoard: UIView {
    
    enum ZYDirection {
        case up
        case down
        case left
        case right
    }
    
    var gameOver : (() -> ())?
    var scoreChanged : ((Int) -> ())?
    
    private var tileCells = [ZYTileCell]()
    private var currentID = 0
    private var isSameNumExist = false
    private var isAnyLineSameNumExist = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        
        setupSubviews()
        
    }
    
    private func setupSubviews() {
        
        for index in 0..<cellRowCount * cellRowCount {
            
            let row = index / cellRowCount
            let column = index % cellRowCount
            
            let cellBgView = UIView(frame: tileCellFrame(row: row, column: column))
            cellBgView.backgroundColor = UIColor.darkGray
            cellBgView.layer.cornerRadius = 5
            cellBgView.clipsToBounds = true
            self.addSubview(cellBgView)
            
        }
        
        let upGest = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        upGest.direction = .up
        self.addGestureRecognizer(upGest)
        
        let downGest = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        downGest.direction = .down
        self.addGestureRecognizer(downGest)
        
        let leftGest = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        leftGest.direction = .left
        self.addGestureRecognizer(leftGest)
        
        let rightGest = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        rightGest.direction = .right
        self.addGestureRecognizer(rightGest)
        
    }
    
    // MARK: - 重置游戏数据
    
    func resetGame() {
        for tileCell in self.tileCells {
            tileCell.removeFromSuperview()
        }
        self.tileCells.removeAll()
    }
    
    // MARK: - Swipe手势的响应方法
    
    @objc private func swipeUp() {
        swipeAction(direction: .up, needMove: true)
    }
    
    @objc private func swipeDown() {
        swipeAction(direction: .down, needMove: true)
    }
    
    @objc private func swipeLeft() {
        swipeAction(direction: .left, needMove: true)
    }
    
    @objc private func swipeRight() {
        swipeAction(direction: .right, needMove: true)
    }
    
    // MARK: - 执行各个方向的滑动操作
    
    private func swipeAction(direction: ZYDirection, needMove: Bool) {
        
        var cellLines = [[ZYTileCell]]()
        for _ in 0..<4 {
            cellLines.append([ZYTileCell]())
        }
        
        for tileCell in tileCells {
            for index in 0..<cellLines.count {
                if ((direction == .up || direction == .down) && tileCell.tilePath.column == index) || ((direction == .left || direction == .right) && tileCell.tilePath.row == index) {
                    cellLines[index].append(tileCell)
                }
            }
        }
        var sortWay : (ZYTileCell, ZYTileCell) -> Bool
        switch direction {
        case .up:
            sortWay = { (cell1, cell2) -> Bool in
                return cell1.tilePath.row < cell2.tilePath.row
            }
            break
        case .down:
            sortWay = { (cell1, cell2) -> Bool in
                return cell1.tilePath.row > cell2.tilePath.row
            }
            break
        case .left:
            sortWay = { (cell1, cell2) -> Bool in
                return cell1.tilePath.column < cell2.tilePath.column
            }
            break
        case .right:
            sortWay = { (cell1, cell2) -> Bool in
                return cell1.tilePath.column > cell2.tilePath.column
            }
            break
        }
        var combinedCellLines = [[ZYTileCell]]()
        isAnyLineSameNumExist = false
        for index in 0..<cellLines.count {
            let sortedLine = cellLines[index].sorted(by: sortWay)
            cellLines[index] = sortedLine
            combinedCellLines.append(findSameNumAndCombine(needMove: needMove, sortedCells: sortedLine))
            if isSameNumExist {
                isAnyLineSameNumExist = true
            }
        }
        if needMove {
            moveTile(direction: direction, cellLines: cellLines, combinedCellLines: combinedCellLines)
            addRandomTileCell()
        }
    }
    
    // MARK: - 移动数字块儿
    
    private func moveTile(direction: ZYDirection, cellLines: [[ZYTileCell]], combinedCellLines: [[ZYTileCell]]) {
        for (lineIndex, lineCells) in cellLines.enumerated() {
            var needMoreStep = false
            for (index, originCell) in lineCells.enumerated() {
                
                let combinedCells = combinedCellLines[lineIndex]
                var toIndex = index
                var distance : CGFloat = 0
                var cellFrame = originCell.frame
                
                if toIndex > combinedCells.count - 1 {
                    toIndex = combinedCells.count - 1
                }
                var delta = 0
                if needMoreStep {
                    delta = 1
                }
                
                switch direction {
                case .up:
                    distance = CGFloat(toIndex - originCell.tilePath.row - delta) * (originCell.frame.height + margin)
                    cellFrame.origin.y += distance
                    originCell.tilePath = ZYTilePath(row: toIndex, column: lineIndex)
                    break
                case .down:
                    toIndex = 3 - toIndex
                    distance = CGFloat(toIndex - originCell.tilePath.row + delta) * (originCell.frame.height + margin)
                    cellFrame.origin.y += distance
                    originCell.tilePath = ZYTilePath(row: toIndex, column: lineIndex)
                    break
                case .left:
                    distance = CGFloat(toIndex - originCell.tilePath.column - delta) * (originCell.frame.height + margin)
                    cellFrame.origin.x += distance
                    originCell.tilePath = ZYTilePath(row: lineIndex, column: toIndex)
                    break
                case .right:
                    toIndex = 3 - toIndex
                    distance = CGFloat(toIndex - originCell.tilePath.column + delta) * (originCell.frame.height + margin)
                    cellFrame.origin.x += distance
                    originCell.tilePath = ZYTilePath(row: lineIndex, column: toIndex)
                    break
                }
                needMoreStep = originCell.isCombined
                if distance != 0 {
                    UIView.animate(withDuration: 0.1, animations: {
                        originCell.frame = cellFrame
                    }, completion: { (_) in
                        if originCell.isCombined == false { return }
                        originCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(rawValue: 0), animations: {
                            originCell.transform = CGAffineTransform.identity
                        }, completion: nil)
                    })
                }
            }
        }
    }
    
    // MARK: - 查找滑动方向是否有相同的数字块儿
    
    private func findSameNumAndCombine(needMove: Bool, sortedCells: [ZYTileCell]) -> [ZYTileCell] {
        if sortedCells.count < 2 { return sortedCells}
        isSameNumExist = false
        var newTileCells = [ZYTileCell]()
        for tileCell in sortedCells {
            newTileCells.append(tileCell)
        }
        var combinedIndex = 1000
        for (cellIndex, cell) in sortedCells.enumerated() {
            cell.isCombined = false
            if cellIndex + 1 < sortedCells.count && cellIndex != combinedIndex + 1 {
                if sortedCells[cellIndex].num == sortedCells[cellIndex + 1].num {
                    if needMove {
                        cell.num = cell.num! * 2
                        if isSameNumExist {
                            newTileCells.remove(at: cellIndex)
                        }else {
                            newTileCells.remove(at: cellIndex + 1)
                        }
                        let extraCell = sortedCells[cellIndex + 1]
                        UIView.animate(withDuration: 0.1, animations: {
                            extraCell.alpha = 0
                        }, completion: { (_) in
                            extraCell.removeFromSuperview()
                        })
                        var index = 0
                        for tileCell in tileCells {
                            if extraCell.cellID == tileCell.cellID {
                                break
                            }
                            index += 1
                        }
                        if index < tileCells.count {
                            tileCells.remove(at: index)
                        }
                        cell.isCombined = true
                        if scoreChanged != nil {
                            scoreChanged!(cell.num!)
                        }
                    }
                    combinedIndex = cellIndex
                    isSameNumExist = true
                }
            }
        }
        print(newTileCells)
        print("")
        return newTileCells
    }
    
    // MARK: - 在随机位置添加数字块儿
    
    private func addRandomTileCell() {
        
        var tilePaths = [ZYTilePath]()
        for index in 0..<cellRowCount * cellRowCount {
            let row = index / cellRowCount
            let column = index % cellRowCount
            tilePaths.append(ZYTilePath(row: row, column: column))
        }
        if tileCells.count > 0 {
            for tileCell in tileCells {
                for (index, tilePath) in tilePaths.enumerated() {
                    if tileCell.tilePath.row == tilePath.row && tileCell.tilePath.column == tilePath.column {
                        tilePaths.remove(at: index)
                    }
                }
            }
        }
        if tilePaths.count == 0 {
            swipeAction(direction: .up,    needMove: false)
            let upSameNumExist = isAnyLineSameNumExist
            swipeAction(direction: .down,  needMove: false)
            let downSameNumExist = isAnyLineSameNumExist
            swipeAction(direction: .left,  needMove: false)
            let leftSameNumExist = isAnyLineSameNumExist
            swipeAction(direction: .right, needMove: false)
            let rightSameNumExist = isAnyLineSameNumExist
            if gameOver != nil && !(upSameNumExist || downSameNumExist || leftSameNumExist || rightSameNumExist) {
                gameOver!()
            }
            return
        }
        let randomTilePath = tilePaths[Int(arc4random_uniform(UInt32(tilePaths.count) - 1))]
        let tileCell = ZYTileCell(indexPath: randomTilePath, cellID: currentID)
        currentID += 1
        tileCell.num = arc4random() % 3 == 0 ? 4 : 2
        tileCells.append(tileCell)
        tileCell.frame = tileCellFrame(row: randomTilePath.row, column: randomTilePath.column)
        addSubview(tileCell)
        
        tileCell.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(rawValue: 0), animations: {
            tileCell.transform = CGAffineTransform.identity
        }, completion: nil)
        
    }
    
    private func tileCellFrame(row: Int, column: Int) -> CGRect {
        let cellWH = (frame.width - margin * CGFloat(cellRowCount + 1)) / CGFloat(cellRowCount)
        let cellX = CGFloat(column) * (cellWH + margin) + margin
        let cellY = CGFloat(row) * (cellWH + margin) + margin
        return CGRect(x: cellX, y: cellY, width: cellWH, height: cellWH)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
