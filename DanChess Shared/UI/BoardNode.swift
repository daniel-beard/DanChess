//
//  BoardNode.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

class BoardNode: SKNode {

    private var squares = Array2D<SKShapeNode>(cols: 8, rows: 8, defaultValues: nil)
    private var pieces = Array2D<Piece>(cols: 8, rows: 8, defaultValues: nil)
    let squareSize: Int

    required init?(coder aDecoder: NSCoder) {
        squareSize = 32
        super.init(coder: aDecoder)
        setupSquares()
    }

    init(frame: CGRect, fenString: String? = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
        self.squareSize = Int(min(frame.size.width, frame.size.height) / 8)
        super.init()
        setupSquares()
        if let fenString = fenString {
            setupPieces(with: fenString)
        }
    }

    private func setupSquares() {
        let light = SKColor(deviceRed: 235 / 255, green: 215/255, blue: 185/255, alpha: 1)
        let dark = SKColor(deviceRed: 175 / 255, green: 135 / 255, blue: 105 / 255, alpha: 1)
        for file in 0..<8 {
            for rank in 0..<8 {
                let square = SKShapeNode(rect:
                    CGRect(x: file * squareSize,
                           y: rank * squareSize,
                           width: squareSize,
                           height: squareSize))
                square.fillColor = (file + rank) % 2 != 0 ? light : dark
                addChild(square)
                squares[rank, file] = square
                print("Rank: \(rank) file: \(file)")
            }
        }
    }

    private func setupPieces(with fenString: String) {
        /**
         A FEN "record" defines a particular game position, all in one text line and using only the ASCII character set. A text file with only FEN data records should have the file extension ".fen".[4]

         A FEN record contains six fields. The separator between fields is a space. The fields are:[5]

         1. Piece placement (from White's perspective). Each rank is described, starting with rank 8 and ending with rank 1; within each rank, the contents of each square are described from file "a" through file "h". Following the Standard Algebraic Notation (SAN), each piece is identified by a single letter taken from the standard English names (pawn = "P", knight = "N", bishop = "B", rook = "R", queen = "Q" and king = "K"). White pieces are designated using upper-case letters ("PNBRQK") while black pieces use lowercase ("pnbrqk"). Empty squares are noted using digits 1 through 8 (the number of empty squares), and "/" separates ranks.

         2. Active color. "w" means White moves next, "b" means Black moves next.

         3. Castling availability. If neither side can castle, this is "-". Otherwise, this has one or more letters: "K" (White can castle kingside), "Q" (White can castle queenside), "k" (Black can castle kingside), and/or "q" (Black can castle queenside). A move that temporarily prevents castling does not negate this notation.

         4. En passant target square in algebraic notation. If there's no en passant target square, this is "-". If a pawn has just made a two-square move, this is the position "behind" the pawn. This is recorded regardless of whether there is a pawn in position to make an en passant capture.[6]

         5. Halfmove clock: This is the number of halfmoves since the last capture or pawn advance. The reason for this field is that the value is used in the fifty-move rule.[7]

         6. Fullmove number: The number of the full move. It starts at 1, and is incremented after Black's move.
         */

        /// Starting position FEN
        /// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
        let pieceMapping: [String: Piece] = [
            "r": [.rook, .black],
            "n": [.knight, .black],
            "b": [.bishop, .black],
            "q": [.queen, .black],
            "k": [.king, .black],
            "p": [.pawn, .black],
            "R": [.rook, .white],
            "N": [.knight, .white],
            "B": [.bishop, .white],
            "Q": [.queen, .white],
            "K": [.king, .white],
            "P": [.pawn, .white],
        ]

        var rank: Rank = .eight
        var file: File = .a
        var finishedPlacingBoard = false
        for char in fenString {
            if char == " " {
                finishedPlacingBoard = true
                break
            }
            if char.isNumber, let number = Int(String(char)) {
                file = (file + (number - 1)) ?? .a
                continue
            }
            if char == "/" {
                rank = (rank - 1) ?? .one
                file = .a
                continue
            }
            let piece = pieceMapping[String(char)]!
            pieces[rank, file] = piece
            let sprite = pieceSprite(for: piece)!
            addChild(sprite)
            sprite.position = CGPoint(x: (file.rawValue - 1) * squareSize + squareSize / 2, y: (rank.rawValue - 1) * squareSize + squareSize / 2)
            file = (file + 1) ?? .a
        }

//        // Setup initial pieces
//        //White pieces
//        pieces[.one, .a] = [.rook, .white]
//        pieces[.one, .b] = [.knight, .white]
//        pieces[.one, .c] = [.bishop, .white]
//        pieces[.one, .d] = [.queen, .white]
//        pieces[.one, .e] = [.king, .white]
//        pieces[.one, .f] = [.bishop, .white]
//        pieces[.one, .g] = [.knight, .white]
//        pieces[.one, .h] = [.rook, .white]
//        pieces[.two, .a] = [.pawn, .white]
//        pieces[.two, .b] = [.pawn, .white]
//        for x in 0..<pieces.cols {
//            for y in 0..<pieces.rows {
//                if let piece = pieces[x, y] {
//                    let sprite = pieceSprite(for: piece)!
//                    addChild(sprite)
//                    sprite.position = CGPoint(x: x * squareSize + squareSize / 2, y: y * squareSize + squareSize / 2)
//                    print(squares[x, y]!.position)
//                }
//            }
//        }
    }
}
