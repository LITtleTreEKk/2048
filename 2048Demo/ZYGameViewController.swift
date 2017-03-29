//
//  ZYGameViewController.swift
//  2048Demo
//
//  Created by wpsd on 2017/3/24.
//  Copyright © 2017年 wpsd. All rights reserved.
//

import UIKit

class ZYGameViewController: UIViewController {
    
    var score = 0 {
        didSet{
            scoreView?.text = "SCORE:\(score)"
        }
    }
    
    var scoreView : UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        setupUI()
        
    }
    
    private func setupUI() {
        
        let boardWH = SCREEN_WIDTH - boardLeftMargin * 2
        let gameBoard = ZYGameBoard(frame: CGRect(x: 0, y: 0, width: boardWH, height: boardWH))
        gameBoard.center = view.center
        gameBoard.gameOver = {
            let alertContr = UIAlertController(title: "提示", message: "游戏失败，请重试", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "确定", style: .default, handler: { (alertAction) in
                gameBoard.resetGame()
                self.score = 0
            })
            alertContr.addAction(confirmAction)
            self.present(alertContr, animated: true, completion: nil)
        }
        gameBoard.scoreChanged = { score in
            self.score += score
        }
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

}
