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

    override var isUserInteractionEnabled: Bool {
        set { }
        get { true }
    }

    override var name: String? {
        set { }
        get { "promotion" }
    }

    let pieceSelection: (Piece) -> ()

    init(color: TeamColor,
         position: Position,
         board: BoardNode,
         onPieceSelection: @escaping (Piece) -> ()) {

        self.color = color
        pieceSelection = onPieceSelection
        super.init()
        pieces = [
            [.bishop, color.toPieceColor()],
            [.knight, color.toPieceColor()],
            [.rook,   color.toPieceColor()],
            [.queen,  color.toPieceColor()],
        ]

        let spriteSize = pieces[0].sprite().size.width
        zPosition = 100

        // background
        let width = strokeSize * 2 + spriteSize * Double(pieces.count)
        let height = strokeSize * 2 + spriteSize
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height))
        background.fillColor = SKColor._dbcolor(red: 205/255, green: 87/255, blue: 87/255)
        background.strokeColor = SKColor._dbcolor(red: 0, green: 0, blue: 0)
        background.lineWidth = 2.0
        self.addChild(background)

        // pieces
        var xOffset = -((width / 2.0) - spriteSize / 2.0)
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

    override func mouseDragged(with event: NSEvent) {
    }

    override func mouseUp(with event: NSEvent) {
    }
#endif

    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }
}
