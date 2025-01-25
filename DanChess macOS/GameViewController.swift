//
//  GameViewController.swift
//  DanChess macOS
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

    var scene: GameScene = GameScene.newGameScene(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

    override func viewDidLoad() {
        super.viewDidLoad()

        present(scene: scene)
    }

    func present(scene: GameScene) {
        self.scene = scene

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true

        skView.showsFPS = true
        skView.showsNodeCount = true
    }


}

