//
//  GameScene.swift
//  DanChess Shared
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {

    fileprivate var board: BoardNode!
    fileprivate var selectedPiece: SKNode?
    fileprivate var selectedPieceStartUIPosition: CGPoint?
    fileprivate var selectedPieceStartBoardPosition: Position?

    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.scaleMode = .aspectFill
        return scene
    }
    
    func setUpScene() {
        board = BoardNode(frame: self.frame, fenString: "rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")
        addChild(board)
        board.position = CGPoint(x: 0 - (self.frame.size.width / 2), y: 0 - (self.frame.size.height / 2))
    }

    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let firstTouchedNode = atPoint(location)
        let boardPoint = event.location(in: board)
        if let position = board.position(forUIPosition: boardPoint) {
            board.displayPossibleMoves(forPieceAt: position)
            if board.canPickupPiece(at: position) && firstTouchedNode.name?.starts(with: "piece") ?? false {
                selectedPiece = firstTouchedNode
                selectedPieceStartUIPosition = selectedPiece?.position
                selectedPieceStartBoardPosition = position
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        let boardPosition = event.location(in: board)
        selectedPiece?.position = boardPosition
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let startBoardPos = selectedPieceStartBoardPosition,
            let startPoint = selectedPieceStartUIPosition else { return }
        let boardPoint = event.location(in: board)
        if let nextBoardPos = board.position(forUIPosition: boardPoint) {
            if board.canMove(from: startBoardPos, to: nextBoardPos) {
                // make move
                board.makeMove(from: startBoardPos, to: nextBoardPos)
                selectedPiece?.run(SKAction.move(to: board.uiPosition(forBoardPosition: nextBoardPos), duration: 0.1))
            } else {
                // animate back to starting point
                selectedPiece?.run(SKAction.move(to: startPoint, duration: 0.3))
            }
        }
        selectedPiece = nil
        selectedPieceStartBoardPosition = nil
        selectedPieceStartUIPosition = nil
    }

}
#endif

