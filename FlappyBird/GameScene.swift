//
//  GameScene.swift
//  FlappyBird
//
//  Created by mikako kinugawa on 2019/10/11.
//  Copyright © 2019 mikako.kinugawa. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //暗黙的なオプショナル型で宣言。使用時にアンラップする必要がなくなる。
    var scrollNode:SKNode!  //地面と雲
    var wallNode:SKNode!   //壁
    var bird:SKSpriteNode! //鳥
    var itemNode:SKNode!   //風船
    
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001 鳥
    let groundCategory: UInt32 = 1 << 1     // 0...00010　地面
    let wallCategory: UInt32 = 1 << 2       // 0...00100　壁
    let scoreCategory: UInt32 = 1 << 3      // 0...01000　スコア用の物体（上側の壁と下側の壁の間に見えない物体）
    let itemCategory: UInt32 = 1 << 4       // 0...10000  風船
    
    // スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    
    // 風船スコア用
    var itemscore = 0
    var itemscoreLabelNode:SKLabelNode!
    
    //ベストスコア保管用
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //BGM音楽用
    let music = SKAudioNode.init(fileNamed: "skyhigh.mp3")
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定 alphaは透明度
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノードを作成。地面と雲用。ゲームオーバーになったときにスクロールを一括で止めることができるようにするため。
        //ノード自体は画面に表示されないため、SKSpriteNodeクラスではなくSKNodeクラスを使う。
        scrollNode = SKNode()
        //addChildメソッドでシーンに親ノードを表示。
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 風船用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)

        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupitem()
        
        setupScoreLabel()
        
        //BGM流す
        print("音楽再生")
        self.addChild(music)
        
    }
    
    //BGM用
    //func setupMusic() {
        
        //BGM音楽を取得
        //let music = SKAudioNode.init(fileNamed: "skyhigh.mp3")
        
        // 鳥が動いていたらBGM音楽を再生
        //if bird.speed == 1 {
            //print("音楽再生")
            //self.addChild(music)
        //}
        
        // 鳥が止まっているときはBGM音楽を止める
        //else if bird.speed == 0 {
            //print("音楽止まる")
            //music.run(SKAction.stop())
        //}
        
    //}
    
    func setupitem() {
        // 風船の画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear
        
        // 移動する距離を計算　(画面の縦幅と風船の縦幅を足した分)
        let movingDistance = CGFloat(self.frame.size.height + itemTexture.size().height)
        
        // 画面上まで6秒かけて移動するアクション
        let moveItem = SKAction.moveBy(x: 0, y:movingDistance , duration:6)
        
        // 自身を取り除くアクション
        let removeItem = SKAction.removeFromParent()
        
        // アニメーションを実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
    
        // 風船を生成するアクションを作成
        let createItemAnimation = SKAction.run({
            
            //風船を乗せるノードを作成
            //let itemBoard = SKNode()
            //itemBoard.position = CGPoint(x: self.frame.size.width * 0.2, y: 0)
            //itemBoard.zPosition = -40

            // 風船作成
            let item = SKSpriteNode(texture: itemTexture)
            item.position = CGPoint(x: self.frame.size.width * 0.2, y: 0)
            item.zPosition = -40

            // 物理演算を設定
            item.physicsBody = SKPhysicsBody(circleOfRadius: item.size.height / 2)
            item.physicsBody?.isDynamic = false

            //　衝突判定カテゴリーを設定
            item.physicsBody?.categoryBitMask = self.itemCategory
            item.physicsBody?.contactTestBitMask = self.birdCategory //衝突する相手
            
            //
            //itemBoard.addChild(item)
            
            // スコアアップ用のノード
            //let itemScoreNode = SKNode()
            //itemScoreNode.position = CGPoint(x: item.size.width, y: item.size.height)
            //itemScoreNode.physicsBody = SKPhysicsBody(rectangleOf: item.size)
            //itemScoreNode.physicsBody?.isDynamic = false
            //itemScoreNode.physicsBody?.categoryBitMask = self.itemCategory
            //itemScoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            //itemBoard.addChild(itemScoreNode)
            
            //
            item.run(itemAnimation)
            
            //
            self.itemNode.addChild(item)
 
        })
        // 10秒待つアクション
        let waitAnimation = SKAction.wait(forDuration: 10)
        // 風船を作成->時間待ち->風船を作成を無限に繰り返すアクションを作成
        let fusenRepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(fusenRepeatForeverAnimation)

    }
    
    
    func setupGround() {
        // 地面の画像を読み込む。SKTextureクラスを作成。表示する画像をSKTextureで扱うため。
        //指定するファイル名は@2xや@3x、拡張子は付けない。2倍や3倍はデバイスによって自動的に判断されるため。
        let groundTexture = SKTexture(imageNamed: "ground")
        //SKTextureクラスのfilteringModeプロパティで、画質優先か処理速度優先か決めれる。
        //.nearestは画像が荒くなるが処理が速い。.linearは画像がきれいだが処理が遅い。
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        //必要な枚数だけ繰り返す
        for i in 0..<needNumber {
            //地面の画像のスプライトを作成。
            let sprite = SKSpriteNode(texture: groundTexture)

        // スプライトの表示する位置を指定する
        //positionで指定するのはNodeの中心位置。
        //SpriteKitの座標は左下が原点。画像の幅と高さの半分を指定しているため、地面の画像は画面の左下にぴったり表示される。
        sprite.position = CGPoint(
            x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
            y: groundTexture.size().height / 2
        )
        
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            // addChild(_:）メソッドでシーンにスプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)

            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算　画面の横幅と壁の横幅を足した分
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで4秒かけて移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        
        // 隙間位置の上下の振れ幅を鳥のサイズの4倍とする
        let random_y_range = birdSize.height * 4
        
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2

        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)

            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory //自身のカテゴリを指定
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory //跳ね返る相手
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory //衝突する相手
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
           // 鳥の速度をゼロにする
           bird.physicsBody?.velocity = CGVector.zero
        
           // 鳥に縦方向の力を与える
           bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))

            
        } else if bird.speed == 0 {
            restart()
    
        }
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        
        //bodyAとbodyBを入れる用
        var ABody: SKNode!
        var BBody: SKNode!
        
        // ゲームオーバーのときは何もしない。壁にあったあとに地面にも必ず衝突するのでそこで2度めの処理を行わないようにする。
        if scrollNode.speed <= 0 {
            return
        }
        
        //壁の間の物体用
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize() //保管するメソッド
            }
        }
        
        //風船用
        else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            
            //風船スコアを更新
            print("風船GET")
            itemscore += 1
            itemscoreLabelNode.text = "ItemScore:\(itemscore)"
            
            //風船の割れた音を出す
            let music = SKAction.playSoundFileNamed("burst.mp3", waitForCompletion: false)
            self.run(music)
            

            //bodyABのノードを取り出す
            ABody = contact.bodyA.node
            BBody = contact.bodyB.node
            
            if ABody == bird {
                print("消える")
                BBody.removeFromParent()
            } else {
                print("消える")
                ABody.removeFromParent()
            }
            
        }
        
        //壁か地面と衝突用
        else {
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            //衝突音楽を流す
            let boyonmusic = SKAction.playSoundFileNamed("boyon1.mp3", waitForCompletion: false)
            self.run(boyonmusic)
            
            //BGMを止める
            print("音楽止まる")
            music.run(SKAction.stop())
            
            
            //鳥が壁に衝突したときに地面まで落下させるため、一時的にcollisionBitMaskをgroundCategoryだけにして壁とは衝突しないようにする
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //衝突してしまったことを表現するために鳥を回転、回転が終わった時にbirdのspeedも0にして完全に停止
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }

    func restart() {
        
        //壁用スコア
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
        //風船用スコア
        itemscore = 0
        itemscoreLabelNode.text = "ItemScore:\(itemscore)"
        
        //鳥を指定の位置へ。鳥の速度を0へ。鳥が跳ね返る相手を壁と地面へ。鳥の表示を一番手前へ。
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        //スピードを1に戻す
        bird.speed = 1
        scrollNode.speed = 1
        
        //BGM流す
        print("音楽再生")
        self.addChild(music)
        
        
    }
    
    
    func setupScoreLabel() {
        
        //風船スコアラベル
        itemscore = 0
        itemscoreLabelNode = SKLabelNode()
        itemscoreLabelNode.fontColor = UIColor.black
        itemscoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        itemscoreLabelNode.zPosition = 100
        itemscoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemscoreLabelNode.text = "ItemScore:\(itemscore)"
        self.addChild(itemscoreLabelNode)
        
        //壁用スコアラベル
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        //ベストスコアラベル
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
}

