//
//  GameScene.swift
//  DanChess Shared
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

final class GameScene: SKScene {

    private var board: BoardNode!
    private var selectedPiece: SKNode?
    private var selectedPieceStartUIPosition: CGPoint?
    private var selectedPieceStartBoardPosition: Position?

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
        board = BoardNode(frame: self.frame, fenString: "rnb1kbnr/pp1P1ppp/8/q1p1p3/8/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")
        addChild(board)
        board.position = CGPoint(x: 0 - (self.frame.size.width / 2), y: 0 - (self.frame.size.height / 2))
        board.delegate = self
    }

    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

//TODODB: Add callbacks for selections?
class PromotionUI: SKNode {
    var pieces = [SKSpriteNode]()
    let strokeSize = 3.0
    init(color: TeamColor, position: Position, board: BoardNode) {
        super.init()
        pieces.append(pieceSprite(for: [.bishop, color.toPieceColor()]))
        pieces.append(pieceSprite(for: [.knight, color.toPieceColor()]))
        pieces.append(pieceSprite(for: [.rook,   color.toPieceColor()]))
        pieces.append(pieceSprite(for: [.queen,  color.toPieceColor()]))

        //TODODB: Fix this up
        let spriteSize = 90.0

        // background
        let width = strokeSize * 2 + spriteSize * Double(pieces.count)
        let height = strokeSize * 2 + spriteSize
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height))
        background.fillColor = SKColor._dbcolor(red: 1.0, green: 0, blue: 0)
        background.strokeColor = SKColor._dbcolor(red: 0, green: 0, blue: 0)

        //TODODB: Add sprites here

        self.addChild(background)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }
}

extension GameScene: BoardDelegate {
    func playerPromotingPawn(at position: Position) {
        //TODODB: draw selection UI
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

    //TODODB: Remove once the UI is in place
    override func keyUp(with event: NSEvent) {
        guard case .keyUp = event.type else { return }
        var piece: Piece? = nil
        let color = board.turn.toPieceColor()
        switch event.characters {
            case "q": piece = [.queen, color]
            case "b": piece = [.bishop, color]
            case "n": piece = [.knight, color]
            case "r": piece = [.rook, color]
            default: return
        }
        guard let piece else { return }
        board.choosePromotionPiece(piece)
    }

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

