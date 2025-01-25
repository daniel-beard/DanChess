//
//  GameScene.swift
//  DanChess Shared
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

final class GameScene: SKScene {

    var board: BoardNode!
    private var startFEN: String = START_FEN
    private var selectedPiece: SKNode?
    private var selectedPieceStartUIPosition: CGPoint?
    private var selectedPieceStartBoardPosition: Position?

    class func newGameScene(fen: String = START_FEN) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.startFEN = fen
        scene.scaleMode = .aspectFill
        return scene
    }
    
    func setUpScene() {
        board = BoardNode(frame: frame, fenString: startFEN)
        addChild(board)
        board.position = CGPoint(x: 0 - (frame.size.width / 2), y: 0 - (frame.size.height / 2))
        board.delegate = self
    }

    override func didMove(to view: SKView) {
        self.setUpScene()
    }
}

extension GameScene: BoardDelegate {
    func playerPromotingPawn(at position: Position) {
        let promotionUI = PromotionUI(color: board.turn, position: position, board: board, onPieceSelection: { piece in
            self.board.replace(piece: piece, at: position)
            self.board.gameMode = .regular
            self.board.turn = self.board.turn.toggle()
        })
        promotionUI.setPosition(forPosition: position)
        board.addChild(promotionUI)
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
            // Bail if we are promoting a piece
            guard case .regular = board.gameMode else { return }
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
                selectedPiece?.run(.move(to: board.uiPosition(forBoardPosition: nextBoardPos), duration: 0.1))
            } else {
                // animate back to starting point
                selectedPiece?.run(.move(to: startPoint, duration: 0.3))
            }
        }
        selectedPiece = nil
        selectedPieceStartBoardPosition = nil
        selectedPieceStartUIPosition = nil
    }
}
#endif
