//
//  ViewController.swift
//  FlappyBird
//
//  Created by mikako kinugawa on 2019/10/11.
//  Copyright © 2019 mikako.kinugawa. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.）
        
        //1、ViewをSKViewにする
        //2、その上にSKSceneクラスでシーンという単位で画面をつくる
        
        // ViewをSKView型に変換してて定数skViewに代入している。　as!（強制キャスト）
        let skView = self.view as! SKView
        
        //FPSを表示する　（画面が1秒間に何回更新されているかを画面に表示する）
        skView.showsFPS = true
        
        // ノードの数を表示する　（ノードが幾つ表示されているか画面に表示する）
        skView.showsNodeCount = true
        
        //ノード数が多いと処理が重たくなり結果としてFPSの値が減ってカクカクした動きになる→FPSが極端に落ちないよう注意
        
        //ビューと同じサイズでシーンを作成する。KSceneクラスを継承したGameSceneクラスで作成する。
        let scene = GameScene(size:skView.frame.size)
        
        //ビューにシーンを表示する。（SKViewクラスのpresentScene()メソッドで設定）
        skView.presentScene(scene)
    }
    
    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

