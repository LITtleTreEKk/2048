//
//  ViewController.swift
//  2048Demo
//
//  Created by wpsd on 2017/3/24.
//  Copyright © 2017年 wpsd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButton()
        
    }
    
    private func setupButton() {
        
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.setTitle("Start Game", for: .normal)
        btn.center = view.center
        btn.addTarget(self, action: #selector(btnClick(sender:)), for: .touchUpInside)
        view.addSubview(btn)
        
    }
    
    @objc private func btnClick(sender: UIButton) {
        
        present(ZYGameViewController(), animated: true, completion: nil)
        
    }

}

