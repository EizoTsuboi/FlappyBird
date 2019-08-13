//
//  GameScene.swift
//  FlappyBird
//
//  Created by 坪井衛三 on 2019/08/13.
//  Copyright © 2019 Eizo Tsuboi. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    //SKViewにシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        //背景色
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        let scrollNode = SKNode()
        addChild(scrollNode)
        
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
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            //テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 ,
                y: groundTexture.size().width / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    

    

}
