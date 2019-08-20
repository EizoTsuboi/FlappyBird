//
//  GameScene.swift
//  FlappyBird
//
//  Created by 坪井衛三 on 2019/08/13.
//  Copyright © 2019 Eizo Tsuboi. All rights reserved.
//
//SKScene:Viewの上にシーン（SKSceneクラス)という単位で画面を作る.タイトル画面のシーン、ゲーム画面のシーン
//SKNode :シーン上の画面を構成する要素をノード（SKNodeクラス）.画像を描画するSKSpriteNode,文字を描画するSKLabelNode,図形を描画するSKShapeNode.

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var jewelNode: SKNode!
    var bird: SKSpriteNode!
    var musicNode: SKAudioNode!
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let jewelCategory: UInt32 = 1 << 4
    
    // スコア用
    var score = 0
    var jewelscore = 0
    var totalscore = 0
    var scoreLabelNode:SKLabelNode!
    var jewelScoreLabelNode:SKLabelNode!
    var totalScoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //SKViewにシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライト（雲,地面）の親ノード
        scrollNode = SKNode()
        addChild(scrollNode) //cloudとgroundのスプライトが入っている
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //jewel用のノード
        jewelNode = SKNode()
        scrollNode.addChild(jewelNode)
        
        //music用のノード
        musicNode = SKAudioNode()
        addChild(musicNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupJewel()
        
        //効果音の再生
        playMusic(music: "BGM", loop: true)
        
        setupScoreLabel()
    }
    
    func setupGround(){
        //地面の画像を読み込む（テクスチャ）
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールするアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        //groundのスプライトを配置する（画像のようなもの）
        for i in 0..<needNumber {
            //テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            //衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width ) + 2
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールするアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 2)
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        //スプライトを配置
        for i in 0..<needCloudNumber{
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるように
            //スプライトの表示する位置を指定
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            sprite.run(repeatScrollCloud)
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall(){
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍にする
        let slit_length = birdSize.height * 3
        //隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        //下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクションを作成
        let createWallAnimeation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 //雲より手前、地面より奥
            
            // 0~ random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //物理演算
            //スプライトに物理演算を設定（rectangleof initializeは四角形の物理ボディを作成）
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            //ノードにスプライトをのせる
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //物理演算
            //スプライトに物理演算を設定（rectangleof initializeは四角形の物理ボディを作成）
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            //衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory //contactTestBitMask <- 衝突することを判定する相手のカテゴリーを設定
            
            wall.addChild(scoreNode)
            //ここまで
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成-> 時間待ち-> 壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimeation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupJewel(){
        //jewelの画像を読み込む
        let jewelTexture = SKTexture(imageNamed: "jewel")
        jewelTexture.filteringMode = .linear
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 1.2 + jewelTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveJewel = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        //自身を取り除くアクションを作成
        let removeJewel = SKAction.removeFromParent()
        //2つのアニメーションを順に実行するアクションを作成
        let jewelAnimation = SKAction.sequence([moveJewel, removeJewel])
        //jewelのY軸下限位置を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let under_jewel_lowest_y = groundSize.height + jewelTexture.size().height / 2
        let upper_jewel_y = self.frame.size.height - jewelTexture.size().height / 2 - groundSize.height
        
        let createJewelAnimeation = SKAction.run({
            let jewel = SKSpriteNode(texture: jewelTexture)
            
            jewel.zPosition = -50 //雲より手前、地面より奥

            // 0~ random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0 ..< upper_jewel_y)
            //Y軸の下限にランダムな値を足して、jewelのY座標を決定
            let under_jewel_y = under_jewel_lowest_y + random_y

            jewel.position = CGPoint(x: self.frame.size.width * 1.2 + jewelTexture.size().width, y: under_jewel_y)
            
            //jewelのスピードをwallと同じにする
            let wallTexture = SKTexture(imageNamed: "wall")
            let movingDistance_wall = CGFloat(self.frame.size.width + wallTexture.size().width)
            let fixspeed: CGFloat = (movingDistance_wall / 4) / (movingDistance / 4 )
            jewel.speed = fixspeed
            
            //物理演算
            //スプライトに物理演算を設定（rectangleof initializeは四角形の物理ボディを作成）
            jewel.physicsBody = SKPhysicsBody(rectangleOf: jewelTexture.size())
            jewel.physicsBody?.categoryBitMask = self.jewelCategory
            jewel.physicsBody?.contactTestBitMask = self.birdCategory

            //衝突の時に動かないように設定する
            jewel.physicsBody?.isDynamic = false

            jewel.run(jewelAnimation)

            self.jewelNode.addChild(jewel)
        })
        //次のjewel作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成-> 時間待ち-> 壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createJewelAnimeation, waitAnimation]))
        
        jewelNode.run(repeatForeverAnimation)
        
    }
    
    func setupBird(){
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
    
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory // <- 当たった時に跳ね返る動作（当てられる判定）
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory //<- 衝突することを判定する相手のカテゴリーを設定
        
        
        bird.run(flap)
        addChild(bird)
    }
    
    //画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            //鳥の速度をゼロ
            bird.physicsBody?.velocity = CGVector.zero
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0{
            restart()
        }
    }
    
    //SKPhysicsCoantactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact){
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0{
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory{
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            if jewelscore != 0{
                totalscore = score * jewelscore
            }else{
                totalscore = score
            }
            totalScoreLabelNode.text = "TotalScore:\(totalscore)"
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if totalscore > bestScore{
                bestScore = totalscore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }else if (contact.bodyA.categoryBitMask & jewelCategory) == jewelCategory || (contact.bodyB.categoryBitMask & jewelCategory) == jewelCategory{
            //jewelと衝突した時
            print("jewelScoreUP")
            jewelscore += 1
            jewelScoreLabelNode.text = "JewelScore:\(jewelscore)"
            
            //衝突したNodeを削除
            contact.bodyA.node?.removeFromParent()
            
            //totalscoreの確認
            if score != 0{
                totalscore = score * jewelscore
            }else{
                totalscore = jewelscore
            }
            totalScoreLabelNode.text = "TotalScore:\(totalscore)"
            //ベストスコア更新か確認
            var bestScore = userDefaults.integer(forKey: "BEST")
            if totalscore > bestScore{
                bestScore = totalscore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            //効果音の再生
            playMusic(music: "touch.mp3", loop: false)
        }else{
            //壁か地面と衝突した
            print("GameOver")
            //スクロールを停止
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })

            //効果音の停止
            self.musicNode.removeAllChildren()
            //効果音の再生
            playMusic(music: "GameOver.mp3", loop: false)

            
        }
    }
    
    func restart(){
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        jewelscore = 0
        jewelScoreLabelNode.text = "JewelScore:\(jewelscore)"
        totalscore = 0
        totalScoreLabelNode.text = "TotalScore:\(totalscore)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        jewelNode.removeAllChildren()
        
        
        bird.speed = 1
        scrollNode.speed = 1
        //効果音の再生
        playMusic(music: "BGM", loop: true)
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //いちばん手前に表示
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        jewelscore = 0
        jewelScoreLabelNode = SKLabelNode()
        jewelScoreLabelNode.fontColor = UIColor.black
        jewelScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        jewelScoreLabelNode.zPosition = 100 //いちばん手前に表示
        jewelScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        jewelScoreLabelNode.text = "JewewlScore:\(jewelscore)"
        self.addChild(jewelScoreLabelNode)
        
        totalscore = 0
        totalScoreLabelNode = SKLabelNode()
        totalScoreLabelNode.fontColor = UIColor.black
        totalScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        totalScoreLabelNode.zPosition = 100 //いちばん手前に表示
        totalScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        totalScoreLabelNode.text = "TotalScore:\(totalscore)"
        self.addChild(totalScoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        bestScoreLabelNode.zPosition = 100 //いちばん手前に表示
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    func playMusic(music: String, loop: Bool){
        let play = SKAudioNode(fileNamed: music)
        play.autoplayLooped = loop
        self.musicNode.addChild(play)
        self.run(
            SKAction.sequence([
              
                SKAction.run {
                    play.run(SKAction.play())
                }
                ])
        )
    }
}
