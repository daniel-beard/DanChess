//
//  BoardNode.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

class BoardNode: SKNode {

    private var squares = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var pieces = Array2D<Piece>(size: 8, defaultValues: nil)
    let squareSize: Int

    /// Game Properties
    var turn: TeamColor = .white
    var whiteCanCastleQueenside = true
    var whiteCanCastleKingside = true
    var blackCanCastleQueenside = true
    var blackCanCastleKingside = true
    var enpassantTarget: (rank: Rank, file: File)? = nil
    var halfMoveClock = 0
    var fullMoveClock = 0

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
                square.isUserInteractionEnabled = false
                addChild(square)
                squares[rank, file] = square
                print("Rank: \(rank) file: \(file)")
            }
        }
    }

    // Takes point in this nodes coord space
    public func position(forUIPosition p: CGPoint) -> Position? {
        let rank: Rank?
        let file: File?
        let s = CGFloat(squareSize)
        // Files
        if p.x > 0 && p.x <= s { file = .a }
        else if p.x > s && p.x <= s * 2 { file = .b }
        else if p.x > s * 2 && p.x <= s * 3 { file = .c }
        else if p.x > s * 3 && p.x <= s * 4 { file = .d }
        else if p.x > s * 4 && p.x <= s * 5 { file = .e }
        else if p.x > s * 5 && p.x <= s * 6 { file = .f }
        else if p.x > s * 6 && p.x <= s * 7 { file = .g }
        else if p.x > s * 7 && p.x <= s * 8 { file = .h }
        else { file = nil }
        // Ranks
        if p.y > 0 && p.y <= s { rank = .one }
        else if p.y > s && p.y <= s * 2 { rank = .two }
        else if p.y > s * 2 && p.y <= s * 3 { rank = .three }
        else if p.y > s * 3 && p.y <= s * 4 { rank = .four }
        else if p.y > s * 4 && p.y <= s * 5 { rank = .five }
        else if p.y > s * 5 && p.y <= s * 6 { rank = .six }
        else if p.y > s * 6 && p.y <= s * 7 { rank = .seven }
        else if p.y > s * 7 && p.y <= s * 8 { rank = .eight }
        else { rank = nil }
        return Position(rank, file)
    }

    private func moveOverlaySprite() -> SKShapeNode {
        let square = SKShapeNode(rect: CGRect(origin: .zero, size: .of(squareSize)))
        square.name = "overlay"
        let color = SKColor(deviceRed: 190/255, green: 37/255, blue: 109/255, alpha: 1)
        square.fillColor = color
        return square
    }

    public func displayPossibleMoves(forPieceAt position: Position) {
        let possibles = possibleMoves(forPieceAt: position)

        // remove existing overlays
        enumerateChildNodes(withName: "overlay") { (node, stop) in
            node.removeFromParent()
        }
        // reset overlays array
        squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
        // add new overlays
        for p in possibles {
            let sprite = moveOverlaySprite()
            sprite.position = CGPoint(x: (p.file.rawValue - 1) * squareSize,
                                      y: (p.rank.rawValue - 1) * squareSize)
            squaresOverlay[p] = sprite
            addChild(sprite)
        }
    }

    //TODO: Naive implementation of possible moves, I need to take into account that if a piece moves that causes check, it's invalid.
    //TODO: An approach here would be to 'paint' the lines of check onces per move
    // That way, we'll save on some of the calculations like for the kings moves or check calculations
    public func possibleMoves(forPieceAt pos: Position) -> [Position] {

        // Get the piece, if there isn't one, there are no moves to return
        guard let piece = pieces[pos] else { return [] }
        let white = piece.contains(.white)
        let currColor = piece.color()

        var potentialMoves: [Position?] = []

        // Now we need to define some types of moves per piece type
        // remember, some pieces can only move in certain directions per color.
        if piece.contains(.pawn) {
            let rankOffset = white ? 1 : -1
            // Can move forward if that position is not taken
            let forwardMove = pos.offset(by: rankOffset, 0)
            if let forwardMove = forwardMove, pieces[forwardMove] == nil {
                potentialMoves.append(forwardMove)
            }
            // Can take on forward left iff there's a piece there
            // Note, this is forward 'stage' left
            //TODO: Need to check colors are different
            let forwardLeftMove = pos.offset(by: rankOffset, -1)
            if let forwardLeftMove = forwardLeftMove,
                let p = pieces[forwardLeftMove],
                currColor != p.color() {
                potentialMoves.append(forwardLeftMove)
            }
            // Can take on forward right iff there's a piece there
            // Note, this is forward 'stage' right
            //TODO: Need to check colors are different
            let forwardRightMove = pos.offset(by: rankOffset, 1)
            if let forwardRightMove = forwardRightMove,
                let p = pieces[forwardRightMove],
                currColor != p.color() {
                potentialMoves.append(forwardRightMove)
            }
            print(potentialMoves)
            // Enpassant
            //TODO
        } else if piece.contains(.rook) {
            let offsets = [(1,0),(-1,0),(0,1),(0,-1)]
            potentialMoves.append(contentsOf: offsets.map {
                movementLine(from: pos, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.knight) {
            let offsets = [(-1,2),(1,2),(2,1),(2,-1),(1,-2),(-1,-2),(-2,-1),(-2,1)]
            potentialMoves.append(contentsOf: offsets.map {
                if let next = pos.offset(by: $0.0, $0.1), pieces[next]?.color() != currColor {
                    return next
                }
                return nil
            })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.bishop) {
            let offsets = [(1,1),(1,-1),(-1,-1),(-1,1)]
            potentialMoves.append(contentsOf: offsets.map {
                movementLine(from: pos, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.queen) {
            let offsets = [(1,0),(1,1),(-1,0),(0,0),(0,1),(0,-1),(-1,-1)]
            potentialMoves.append(contentsOf: offsets.map {
                movementLine(from: pos, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.king) {
            let offsets = [(1,0),(1,1),(-1,0),(0,0),(0,1),(0,-1),(-1,-1)]
            potentialMoves.append(contentsOf: offsets.map {
                movementLine(from: pos, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1)
            }.flatMap { $0 })
            // We can move anywhere that doesn't take us into check
            // And castling is a thing
            //TODO

        }
        return potentialMoves.compactMap { $0 }
    }

    // Returns potential moves as an array along a movement line 'offset'
    // Will include an enemy player if this movement line leads to a taking move.
    // Set maxLength to a smaller value to control the maximum movement line length
    private func movementLine(from position: Position, rankOffset: Int, fileOffset: Int, maxLength: Int = Int.max) -> [Position?] {
        let ourColor = pieces[position]?.color()
        var line = [Position]()
        var currPos = position
        while true {
            if line.count >= maxLength { break }
            guard let next = currPos.offset(by: rankOffset, fileOffset) else { break }
            // Is there a piece at next
            if let nextPiece = pieces[next] {
                if nextPiece.color() != ourColor {
                    line.append(next)
                }
                break
            } else {
                line.append(next)
            }
            currPos = next
        }
        return line
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

         ref (https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation)
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

        enum ParseState: Int {
            case boardPositions = 1
            case activeColor
            case castingAvailability
            case enpassantTarget
            case halfMoveClock
            case fullMoveClock
        }

        var parseState: ParseState = .boardPositions
        var rank: Rank = .eight
        var file: File = .a
        let stringParts = fenString.split(separator: " ")
        if stringParts.count != 6 {
            fatalError("FEN string looks incorrect, does not have required parts")
        }
        for char in fenString {
            if char == " " {
                parseState = ParseState(rawValue: parseState.rawValue + 1)!
                continue
            }
            switch parseState {
                case .boardPositions:
                    if char.isNumber, let number = Int(String(char)) {
                        file = (file + (number)) ?? .a
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
                    let (pieceName, color) = pieceDesc(for: piece)
                    sprite.name = "piece:\(pieceName),\(color)"
                    addChild(sprite)
                    sprite.position = CGPoint(x: (file.rawValue - 1) * squareSize + squareSize / 2, y: (rank.rawValue - 1) * squareSize + squareSize / 2)
                    file = (file + 1) ?? .a
                case .activeColor:
                    print("In active color with: \(char)")
                    if char == "w" { turn = .white }
                    else if char == "b" { turn = .black }
                    else { fatalError("Unknown next turn color: \(char)") }
                case .castingAvailability:
                    if char == "-" {
                        whiteCanCastleKingside = false
                        whiteCanCastleQueenside = false
                        blackCanCastleKingside = false
                        blackCanCastleQueenside = false
                    } else if char == "k" {
                        blackCanCastleKingside = true
                    } else if char == "q" {
                        blackCanCastleQueenside = true
                    } else if char == "K" {
                        whiteCanCastleKingside = true
                    } else if char == "Q" {
                        whiteCanCastleQueenside = true
                    } else {
                        fatalError("Unknown casting availability char: \(char)")
                    }
                case .enpassantTarget:
                    let part = stringParts.suffix(3).first!
                    print("In enpassantTarget with: \(part)")
                    if part == "-" {
                        enpassantTarget = nil
                    } else {
                        guard part.count == 2 else { fatalError("Invalid enpassant target value: \(part)") }
                        let rankString = String(part.first!)
                        let fileString = String(part.last!)
                        enpassantTarget = (Rank(rankString)!, File(fileString)!)
                    }
                case .halfMoveClock:
                    let part = stringParts.suffix(2).first!
                    print("In halfMoveClock with: \(part)")
                    halfMoveClock = Int(String(part)) ?? 0
                case .fullMoveClock:
                    let part = stringParts.suffix(1).joined()
                    print("In fullMoveClock with: \(part)")
                    fullMoveClock = Int(part) ?? 0
            } // switch
        } // for
        // Debug
        print("Active color: \(turn)")
        print("Castling: White Queenside: \(whiteCanCastleQueenside)")
        print("Castling: White Kingside: \(whiteCanCastleKingside)")
        print("Castling: Black Queenside: \(blackCanCastleQueenside)")
        print("Castling: Black Kingside: \(blackCanCastleKingside)")
        print("Enpassant target? \(String(describing: enpassantTarget))")
        print("Half move clock: \(halfMoveClock)")
        print("Full move clock: \(fullMoveClock)")
    } // func
}
