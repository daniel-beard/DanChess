//
//  PromotionUI.swift
//  DanChess
//
//  Created by Daniel Beard on 7/17/22.
//  Copyright © 2022 dbeard. All rights reserved.
//

import Foundation
import SpriteKit

class PromotionUI: SKShapeNode {
    var pieces = [Piece]()
    var pieceLookup = [String: Piece]()
    let color: TeamColor
    let strokeSize = 3.0
    let backgroundHeight: CGFloat

    private var triangleIndicator: SKShapeNode?
    weak var board: BoardNode?

    override var isUserInteractionEnabled: Bool {
        set { } get { true }
    }

    override var name: String? {
        set { } get { "promotion" }
    }

    let pieceSelection: (Piece) -> ()

    init(color: TeamColor,
         position: Position,
         board: BoardNode,
         onPieceSelection: @escaping (Piece) -> ()) {

        self.board = board
        self.color = color
        pieceSelection = onPieceSelection
        pieces = [
            [.bishop, color.toPieceColor()],
            [.knight, color.toPieceColor()],
            [.rook,   color.toPieceColor()],
            [.queen,  color.toPieceColor()],
        ]

        let spriteSize = pieces[0].sprite().size.width

        // background
        let backgroundWidth = strokeSize * 2 + spriteSize * Double(pieces.count)
        backgroundHeight = strokeSize * 2 + spriteSize

        super.init()

        zPosition = 100

        let background = SKShapeNode(rectOf: CGSize(width: backgroundWidth, height: backgroundHeight))
        background.fillColor = promotionFillColor
        background.strokeColor = promotionStrokeColor
        background.lineWidth = 2.0
        self.addChild(background)

        // tail
        let tailSize: CGFloat = 10
        let halfTailSize = tailSize / 2
        var points = [CGPoint(x:tailSize, y:-tailSize / 2.0),
                      CGPoint(x:-tailSize, y:-tailSize / 2.0),
                      CGPoint(x: 0.0, y: tailSize),
                      CGPoint(x:tailSize, y:-tailSize / 2.0)]
        let triangle = SKShapeNode(points: &points, count: points.count)
        triangle.fillColor = promotionFillColor
        triangle.strokeColor = promotionStrokeColor
        triangle.lineWidth = 2
        triangle.position = CGPoint(x: frame.midX, y: (backgroundHeight / 2) + halfTailSize)
        self.addChild(triangle)
        self.triangleIndicator = triangle

        // pieces
        var xOffset = -((backgroundWidth / 2.0) - spriteSize / 2.0)
        for piece in pieces {
            let sprite = piece.sprite()
            sprite.position = CGPoint(x: xOffset, y: strokeSize)
            sprite.zPosition = self.zPosition + 1
            sprite.name = piece.spriteName()
            background.addChild(sprite)
            xOffset += spriteSize

            pieceLookup[piece.spriteName()] = piece
        }
    }

    func setPosition(forPosition position: Position) {
        guard let board else { return }
        let boardSquareSize = CGFloat(board.squareSize)
        var newPosition: CGPoint
        var indicatorOffset: CGFloat = 0
        // Edge two files just use the next neighbor for position of overall promotion UI
        switch position.file {
            case .a:
                newPosition = board.uiPosition(forBoardPosition: Position(position.rank, .b))
                indicatorOffset = -boardSquareSize
            case .h:
                newPosition = board.uiPosition(forBoardPosition: Position(position.rank, .g))
                indicatorOffset = boardSquareSize
            default: newPosition = board.uiPosition(forBoardPosition: position)
        }

        // Need to flip triangle indicator when rank is 1
        if position.rank == .one {
            let tailSize: CGFloat = 10
            triangleIndicator?.zRotation = .pi
            triangleIndicator?.position.y -= backgroundHeight + tailSize
            newPosition.y += (boardSquareSize / 2) + tailSize
        } else {
            newPosition.y -= boardSquareSize / 2
        }

        self.triangleIndicator?.position.x += indicatorOffset
        self.position = newPosition
    }

    // MARK: Touch / Click handling

#if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
#endif

#if os(OSX)
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let firstTouchedNode = atPoint(location)
        let name = firstTouchedNode.name

        guard let name, let piece = pieceLookup[name] else { return }
        self.removeFromParent()
        pieceSelection(piece)
    }

    override func mouseDragged(with event: NSEvent) { }
    override func mouseUp(with event: NSEvent) { }
#endif
    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }
}
