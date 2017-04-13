# 2048
最近在网上下了一个<a href="https://github.com/austinzheng/iOS-2048">仿2048游戏的Demo</a>，发现里面的实现思路做得比较复杂：将数字块的移动操作封装成模型并保存起来，然后根据操作模型的值对滑块逐块地进行操作，具体的实现方式可以自己下下来感受一下。

然后我分析了一下这个游戏，重新整理了一种更简单的实现思路，大体可以分为三步：

* **界面布局**
* **数字块操作**
 * 按方向把所有数字块分成4组，然后进行排序
 * 查找邻近相同数字块，计算该行（列）合并后的块数
 * 按方向整行（列）同时移动数字块
 * 移动块的同时随机添加数字块
* **游戏结束重置游戏**

实现效果如下：

<img src="http://ogdqxib8j.bkt.clouddn.com/2048.gif" width="203" height="384">

<!--more-->
# 具体实现
##界面布局
界面布局是最简单的一步，主要分为三大块：分数栏，游戏背景板和数字块背景，以下是代码：

``` swift
private func setupUI() {
    
    let boardWH = SCREEN_WIDTH - boardLeftMargin * 2
    let gameBoard = ZYGameBoard(frame: CGRect(x: 0, y: 0, width: boardWH, height: boardWH))
    gameBoard.center = view.center
    view.addSubview(gameBoard)
    
    let cellWH = (gameBoard.frame.width - margin * CGFloat(cellRowCount + 1)) / CGFloat(cellRowCount)
    let scoreW = cellWH * 3
    let scoreH = cellWH * 0.9
    scoreView = UILabel(frame: CGRect(x: 0, y: 0, width: scoreW, height: scoreH))
    scoreView?.center = CGPoint(x: SCREEN_WIDTH / 2, y: gameBoard.frame.minY - margin * 2 - scoreH / 2)
    scoreView?.font = UIFont.boldSystemFont(ofSize: 20)
    scoreView?.textAlignment = .center
    scoreView?.textColor = UIColor.white
    scoreView?.backgroundColor = UIColor.gray
    scoreView?.text = "SCORE:0"
    scoreView?.layer.cornerRadius = 8
    scoreView?.clipsToBounds = true
    view.addSubview(scoreView!)
}
```
这里`ZYGameBoard`是一个自定义`View`，在自定义`View`是里面添加了数字块的背景还有所有的数字块移动逻辑，以下是`ZYGameBoard`的界面布局：

``` swift
self.backgroundColor = UIColor.black
self.layer.cornerRadius = 8
self.clipsToBounds = true

for index in 0..<cellRowCount * cellRowCount {

    let row = index / cellRowCount
    let column = index % cellRowCount
    
    let cellBgView = UIView(frame: tileCellFrame(row: row, column: column))
    cellBgView.backgroundColor = UIColor.darkGray
    cellBgView.layer.cornerRadius = 5
    cellBgView.clipsToBounds = true
    self.addSubview(cellBgView)   
}
```
然后，还需要定义数据块的自定义View:

``` swift
class ZYTileCell: UILabel {
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
}
```
其中省略了不同数字块颜色的定义，具体的可以看本文的源代码，见文末。
至此，界面布局部分就完成了。
## 数字块操作
这部分为整个游戏的核心部分，在这部分之前，需要对4个方向添加不同的swipe手势，每个手势添加不同的响应方法，这里略过了，以下具体讲响应方法的具体实现：
### 按方向把所有数字块分成4组，然后进行排序

``` swift
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
```
### 查找邻近相同数字块，计算该行（列）合并后的块数
接下来把排序后的数组相邻的块进行比较，相同的进行合并，把需要删除的数字块从数组移除并执行移除动画：

``` swift
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
    return newTileCells
}
```
在上面的方法里有一个细节就是如果所有的数字块满了，需要挨个模拟各个方向的滑动，在这个方法里判断是否有可以合并的数字块，如果有游戏继续，否则游戏结束。
### 按方向整行（列）同时移动数字块
接下来就可以真正地开始移动数字块了，移动数字块的思路就是**计算出整行或者整列的数字块移动后的最终位置，然后用最终位置和初始位置的差确定位置的距离和方向**。

思路虽然是这样，但在写代码的时候要简单得多，直接遍历整行（整列的）排序后的数字块，下标为最终位置，自身的坐标为初始位置，用这两个值即可计算出位移，坐标轴如下：

<img src="http://ogdqxib8j.bkt.clouddn.com/2048X_Y.jpeg" width="200">

实现代码：

``` swift
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

```

上面的代码对该行存在合并数字块的情况进行了处理：如果该行有数字块合并了（即保留前面一块，移除后面一块），后面所有块都会多移一步，避免中间出现空白。

至此，移动数字块部分也完成了，接下来就是随机添加数字块了。
### 移动块的同时随机添加数字块
这步应该是数字块操作里面最简单的一步，**从所有可能的坐标数组中删除有数字块的元素，剩下都是没有数字块的坐标，在这些坐标中随机选一个添加数字块即可**。

``` swift
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
```

当然，在添加数字块的同时，如果剩余空坐标为0，那么就要进行游戏是否结束的验证，如果游戏结束，就以闭包的形式在控制器进行弹窗操作：

``` swift
// 判断游戏是否结束
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
// 如果游戏结束，在控制器进行操作
gameBoard.gameOver = {
    let alertContr = UIAlertController(title: "提示", message: "游戏失败，请重试", preferredStyle: .alert)
    let confirmAction = UIAlertAction(title: "确定", style: .default, handler: { (alertAction) in
        gameBoard.resetGame()
        self.score = 0
    })
    alertContr.addAction(confirmAction)
    self.present(alertContr, animated: true, completion: nil)
}
```
## 游戏结束重置游戏
接下来就是最后一步，重置游戏数据：

``` swift
func resetGame() {
    for tileCell in self.tileCells {
        tileCell.removeFromSuperview()
    }
    self.tileCells.removeAll()
}
```
好了，大功告成，现在可以装到手机上玩儿一把了。