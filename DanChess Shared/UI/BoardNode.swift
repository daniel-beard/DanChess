//
//  BoardNode.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

enum GameMode {
    case regular
    case whitePawnPromotion
    case blackPawnPromotion
}

/// Board SKNode and game logic
class BoardNode: SKNode {

    private var squares = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var pieces = Array2D<Piece>(size: 8, defaultValues: nil)
    let squareSize: Int

    //TODODB: This isn't implemented right now. Use this to implement promotion
    var gameMode: GameMode = .regular

    /// Game Properties
    var turn: TeamColor = .white
    var whiteCanCastleQueenside = true
    var whiteCanCastleKingside = true
    var blackCanCastleQueenside = true
    var blackCanCastleKingside = true
    var enpassantTarget: Position? = nil
    var halfMoveClock = 0
    var fullMoveClock = 0

    init(frame: CGRect, fenString: String? = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
        self.squareSize = Int(min(frame.size.width, frame.size.height) / 8)
        super.init()
        setupSquares()
        //TODO: Replace this with the parser combinator approach
        if let fenString = fenString {
            setupPieces(with: fenString)
        }
        print("FEN: rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")
        print("FEN: \(fenForCurrentBoard())")
    }
    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }

    private func setupSquares() {

        // just for testing
        fenstrings()

        let light = SKColor._dbcolor(red: 235/255, green: 235/255, blue: 185/255)
        let dark = SKColor._dbcolor(red: 175/255, green: 135/255, blue: 105/255)
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

                // position labels for debug
                let f = File(rawValue: file + 1)!
                let r = Rank(rawValue: rank + 1)!
                let l = SKLabelNode(text: "\(f.debugDescription)\(r.debugDescription)")
                l.fontSize = 20
                l.fontColor = .black
                addChild(l)
                l.position = uiPosition(forBoardPosition: Position(r, f)!)
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

    public func uiPosition(forBoardPosition pos: Position) -> CGPoint {
        return CGPoint(x: (pos.file.rawValue - 1) * squareSize + squareSize / 2, y: (pos.rank.rawValue - 1) * squareSize + squareSize / 2)
    }

    private func moveOverlaySprite() -> SKShapeNode {
        let square = SKShapeNode(rect: CGRect(origin: .zero, size: .of(squareSize)))
        square.name = "overlay"
        let color = SKColor._dbcolor(red: 190/255, green: 37/255, blue: 109/255)
        square.fillColor = color
        return square
    }

    private func removeExistingMoveOverlays() {
        enumerateChildNodes(withName: "overlay") { (node, stop) in
            node.removeFromParent()
        }
        // reset overlays array
        squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    }

    public func displayPossibleMoves(forPieceAt position: Position) {
        removeExistingMoveOverlays()

        // if it's not this colors turn, skip generating the moves
        if pieces[position]?.color() != turn {
            return
        }

        let possibles = possibleMoves(forPieceAt: position)

        // add new overlays
        for p in possibles {
            let sprite = moveOverlaySprite()
            sprite.position = CGPoint(x: (p.file.rawValue - 1) * squareSize,
                                      y: (p.rank.rawValue - 1) * squareSize)
            squaresOverlay[p] = sprite
            addChild(sprite)
        }
    }

    public func canPickupPiece(at pos: Position) -> Bool {
        return pieces[pos]?.color() == turn
    }

    public func canMove(from start: Position, to end: Position) -> Bool {
        let possibles = possibleMoves(forPieceAt: start)
        return possibles.contains(end)
    }

    public func removeNode(at position: Position?) {
        if let position = position {
            self.nodes(at: uiPosition(forBoardPosition: position))
                .filter { $0.name?.starts(with: "piece") ?? false }
                .forEach { $0.removeFromParent() }
        }
    }

    // Calculate if the king is in check for a particular color and board node.
    // This lets us walk forward in time to check future moves.
    public func inCheck(pieces: Array2D<Piece>, teamColor: TeamColor, overlayAttackingPieces: Bool = true) -> Bool {
        // Find the king
        let pieceColor = teamColor == .white ? Piece.white : Piece.black
        let kingPiece = Piece([.king, pieceColor])
        let king = pieces.firstPosition(ofPiece: kingPiece)!

        // Attacking pieces:
        let attackingRooks = rookOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isRook(pieces[pos]) }
        let attackingKnights = knightOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isKnight(pieces[pos]) }
        let attackingBishops = bishopOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isBishop(pieces[pos]) }
        let attackingQueens = queenOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isQueen(pieces[pos]) }
        let attackingKings = kingOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1) }
            .compactMap { $0.last }.filter { pos in isKing(pieces[pos]) }
        let pawnOffsets = pieceColor == .white ? whiteKingAttackingPawnOffsets : blackKingAttackingPawnOffsets
        let attackingPawns = pawnOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1) }
            .compactMap { $0.last }.filter { pos in
                return isPawn(pieces[pos])
            }

        let attackingPieces = [attackingRooks, attackingKnights, attackingBishops, attackingQueens, attackingKings, attackingPawns]
            .flatMap { $0 }.compactMap { $0 }

        if overlayAttackingPieces {
            let overlayPositions: [Position] = attackingPieces.isEmpty ? [] : attackingPieces.appending(king)
            for p in overlayPositions {
                let sprite = moveOverlaySprite()
                sprite.fillColor = SKColor._dbcolor(red: 255/255, green: 165/255, blue: 0/255)
                sprite.position = CGPoint(x: (p.file.rawValue - 1) * squareSize,
                                          y: (p.rank.rawValue - 1) * squareSize)
                squaresOverlay[p] = sprite
                addChild(sprite)
            }
        }

        print("=============================================")
        print("\(teamColor.stringValue) king is at: \(king)")
        print("Attacking rooks: \(attackingRooks)")
        print("Attacking knights: \(attackingKnights)")
        print("Attacking bishops: \(attackingBishops)")
        print("Attacking queens: \(attackingQueens)")
        print("Attacking kings: \(attackingKings)")

        print("FEN for current board: \(fenForCurrentBoard())")
        return true
    }

    public func makeMove(from start: Position, to end: Position) {
        // Need to remove existing enemy piece from UI, if there is one.
        // Filter to any that are pieces whos name does NOT contain our current color
        self.nodes(at: uiPosition(forBoardPosition: end))
            .filter { $0.name?.starts(with: "piece") ?? false && $0.name?.hasSuffix(turn.stringValue) == false }
            .forEach { $0.removeFromParent() }
        let moveColor = turn

        let piece = pieces[start]
        pieces[end] = piece
        pieces[start] = nil
        turn = moveColor.toggle()
        removeExistingMoveOverlays()

        // Promotion TODODB:
        if isPawn(piece) {
            switch (piece?.color(), end.rank) {
            case (.white, .eight): break
            case (.black, .one): break
            default: break
            }
        }

        // Handle enpassant
        if isPawn(piece) && end == enpassantTarget {
            let rankOffset = moveColor == .white ? -1 : 1
            let positionToRemove = end.offset(by: rankOffset, 0)
            removeNode(at: positionToRemove)
            pieces[positionToRemove] = nil
        }
        enpassantTarget = nil

        // Set enpassant target
        if isPawn(piece) && abs(end.rank.rawValue - start.rank.rawValue) == 2 {
            enpassantTarget = start.offset(by: moveColor == .white ? 1 : -1, 0)
        }

        // Handle castling
        if isKing(piece) && moveColor == .white {
            if end == Position(.one, .c) && whiteCanCastleQueenside {
                castleRookMove(start: Position(.one, .a), end: Position(.one, .d))
            }
            if end == Position(.one, .g) && whiteCanCastleKingside {
                castleRookMove(start: Position(.one, .h), end: Position(.one, .f))
            }
            whiteCanCastleQueenside = false
            whiteCanCastleKingside = false
        }
        if isKing(piece) && moveColor == .black {
            if end == Position(.eight, .c) && blackCanCastleQueenside {
                castleRookMove(start: Position(.eight, .a), end: Position(.eight, .d))
            }
            if end == Position(.eight, .g) && blackCanCastleKingside {
                castleRookMove(start: Position(.eight, .h), end: Position(.eight, .f))
            }
            blackCanCastleQueenside = false
            blackCanCastleKingside = false
        }

        // Set castling rules after move for rooks
        if isRook(piece) && moveColor == .white {
            if start == Position(.one, .a) { whiteCanCastleQueenside = false }
            if start == Position(.one, .h) { whiteCanCastleKingside = false }
        }
        if isRook(piece) && moveColor == .black {
            if start == Position(.eight, .a) { blackCanCastleQueenside = false }
            if start == Position(.eight, .h) { blackCanCastleKingside = false }
        }

        //TODODB: Debug only
        let _ = inCheck(pieces: pieces, teamColor: turn)
    }

    private func castleRookMove(start: Position, end: Position) {
        let rook = pieces[start]
        pieces[end] = rook
        pieces[start] = nil
        guard let node = nodes(at: uiPosition(forBoardPosition: start))
                .filter({ $0.name?.starts(with: "piece") ?? false }).first else { return }
        node.position = uiPosition(forBoardPosition: end)
    }

    //TODO: Naive implementation of possible moves, I need to take into account that if a piece moves that causes check, it's invalid.
    //TODO: An approach here would be to 'paint' the lines of check onces per move
    // That way, we'll save on some of the calculations like for the kings moves or check calculations
    public func possibleMoves(forPieceAt pos: Position) -> [Position] {

        // Get the piece, if there isn't one, there are no moves to return
        guard let piece = pieces[pos] else { return [] }
        let white = piece.contains(.white)
        let currColor = piece.color()

        var moves: [Position?] = []

        // Now we need to define some types of moves per piece type
        // remember, some pieces can only move in certain directions per color.
        if piece.contains(.pawn) {
            let rankOffset = white ? 1 : -1
            let homeRank: Rank = (white ? .two : .seven)
            let forward = pos.offset(by: rankOffset, 0)
            let forwardTwo = forward?.offset(by: rankOffset, 0)
            let forwardLeft = pos.offset(by: rankOffset, -1)
            let forwardRight = pos.offset(by: rankOffset, 1)

            // Can move forward if that position is not taken
            if isEmpty(forward) {
                moves.append(forward)
            }
            // Double move from first position if there aren't pieces in the way
            if isEmpty(forward) && isEmpty(forwardTwo) && pos.rank == homeRank {
                moves.append(forwardTwo)
            }
            // Can take on forward left iff there's a piece there
            if let p = pieces[forwardLeft],
                currColor != p.color() {
                moves.append(forwardLeft)
            }
            // Can take on forward right iff there's a piece there
            if let p = pieces[forwardRight],
                currColor != p.color() {
                moves.append(forwardRight)
            }
            // Enpassant
            if let enpassantTarget = enpassantTarget, [forwardLeft, forwardRight].contains(enpassantTarget) {
                moves.append(enpassantTarget == forwardLeft ? forwardLeft : forwardRight)
            }
            //TODO Exchange pieces
            //TODO Check
        } else if piece.contains(.rook) {
            moves.append(contentsOf: rookOffsets.map {
                ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.knight) {
            moves.append(contentsOf: knightOffsets.map {
                if let next = pos.offset(by: $0.0, $0.1), pieces[next]?.color() != currColor {
                    return next
                }
                return nil
            })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.bishop) {
            moves.append(contentsOf: bishopOffsets.map {
                ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.queen) {
            moves.append(contentsOf: queenOffsets.map {
                ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
            //TODO: discard any that would cause our king to be in check
        } else if piece.contains(.king) {
            moves.append(contentsOf: kingOffsets.map {
                ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1)
            }.flatMap{ $0 })
            // Handle castling
            if turn == .white {
                let kingHome = Position(.one, .e)
                if pos == kingHome {
                    // Can castle queenside if no one on d1 or c1 and eligible
                    if whiteCanCastleQueenside && pieces[.one, .d] == nil && pieces[.one, .c] == nil {
                        moves.append(Position(.one, .c))
                    }
                    // Can castle kingside if no one on f1 or g1 and eligible
                    if whiteCanCastleKingside && pieces[.one, .f] == nil && pieces[.one, .g] == nil {
                        moves.append(Position(.one, .g))
                    }
                }
            } else {
                let kingHome = Position(.eight, .e)
                if pos == kingHome {
                    // Can castle queenside if no one on d8 or c8 and eligible
                    if blackCanCastleQueenside && pieces[.eight, .d] == nil && pieces[.eight, .c] == nil {
                        moves.append(Position(.eight, .c))
                    }
                    // Can castle kingside if no one on f8 or g8 and eligible
                    if blackCanCastleKingside && pieces[.eight, .f] == nil && pieces[.eight, .g] == nil {
                        moves.append(Position(.eight, .g))
                    }
                }
            }

            // We can move anywhere that doesn't take us into check
            // TODO
        }

        // TODO: Create a new array with existing possible moves (culling nil values)
        // Add the extra squares that castling would traverse
        // Play forward in all cases, remove the values that would take us into check
        // Return values - extra castling squares

        return moves.compactMap { $0 }
    }

    /** Returns potential moves as an array along a movement line 'offset'
        Will include an enemy player if this movement line leads to a taking move.

        @param from: The position to start searching. We calculate what our color is by looking up the piece at this position.
        @param in: The piece 2D array to read.
        @param rankOffset: rank component of the offset movement line we are walking.
        @param fileOffset: file component of the offset movement line we are walking.
        @param maxLength: Set to a smaller value to control the maximum movement line length
    */
    private func ray(from position: Position, in pieceArray: Array2D<Piece>, rankOffset: Int, fileOffset: Int, maxLength: Int = Int.max) -> [Position?] {
        let ourColor = pieceArray[position]?.color()
        var line = [Position]()
        var currPos = position
        while true {
            if line.count >= maxLength { break }
            guard let next = currPos.offset(by: rankOffset, fileOffset) else { break }
            // Is there a piece at next
            if let nextPiece = pieceArray[next] {
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

    private func isRook(_ piece: Piece?) -> Bool { piece?.contains(.rook) ?? false }
    private func isRook(_ pos: Position?) -> Bool { pieces[pos]?.contains(.rook) ?? false }
    private func isKnight(_ piece: Piece?) -> Bool { piece?.contains(.knight) ?? false }
    private func isKnight(_ pos: Position?) -> Bool { pieces[pos]?.contains(.knight) ?? false }
    private func isBishop(_ piece: Piece?) -> Bool { piece?.contains(.bishop) ?? false }
    private func isBishop(_ pos: Position?) -> Bool { pieces[pos]?.contains(.bishop) ?? false }
    private func isQueen(_ piece: Piece?) -> Bool { piece?.contains(.queen) ?? false }
    private func isQueen(_ pos: Position?) -> Bool { pieces[pos]?.contains(.queen) ?? false }
    private func isKing(_ piece: Piece?) -> Bool { piece?.contains(.king) ?? false }
    private func isKing(_ pos: Position?) -> Bool { pieces[pos]?.contains(.king) ?? false }
    private func isPawn(_ piece: Piece?) -> Bool { piece?.contains(.pawn) ?? false }
    private func isPawn(_ pos: Position?) -> Bool { pieces[pos]?.contains(.pawn) ?? false }
    private func isEmpty(_ pos: Position?) -> Bool { pieces[pos] == nil }

    func fenForCurrentBoard() -> String {
        var components = [String]()

        // Piece positions
        var positionsByRank = [String]()
        for rank in Rank.allCases.reversed() {
            var emptySquareRun = 0
            var rankString = ""
            for file in File.allCases {
                guard let piece = pieces[rank, file] else {
                    emptySquareRun += 1
                    continue
                }
                if emptySquareRun > 0 {
                    rankString += "\(emptySquareRun)"
                    emptySquareRun = 0
                }
                rankString += piece.algebraicNotation
            }
            rankString += emptySquareRun > 0 ? "\(emptySquareRun)" : ""
            positionsByRank.append(rankString)
        }
        components.append(positionsByRank.joined(separator: "/"))

        // Active color
        components.append(turn == .black ? "b" : "w")

        // Castling availability
        if !whiteCanCastleQueenside &&
            !whiteCanCastleKingside &&
            !blackCanCastleQueenside &&
            !blackCanCastleKingside {
            components.append("-")
        } else {
            var castling = ""
            castling += whiteCanCastleKingside  ? "K" : ""
            castling += whiteCanCastleQueenside ? "Q" : ""
            castling += blackCanCastleKingside  ? "k" : ""
            castling += blackCanCastleQueenside ? "q" : ""
            components.append(castling)
        }

        // Enpassant target square
        if let enpassantTarget = enpassantTarget {
            components.append(enpassantTarget.toFen())
        } else {
            components.append("-")
        }

        // Halfmove clock
        components.append("\(halfMoveClock)")

        // Fullmove clock
        components.append("\(fullMoveClock)")

        return components.joined(separator: " ")
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
                    sprite.position = uiPosition(forBoardPosition: Position(rank, file))

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
                    if part == "-" {
                        enpassantTarget = nil
                    } else {
                        guard part.count == 2 else { fatalError("Invalid enpassant target value: \(part)") }
                        let rankString = String(part.first!)
                        let fileString = String(part.last!)
                        enpassantTarget = Position(Rank(rankString)!, File(fileString)!)
                    }
                case .halfMoveClock:
                    let part = stringParts.suffix(2).first!
                    halfMoveClock = Int(String(part)) ?? 0
                case .fullMoveClock:
                    let part = stringParts.suffix(1).joined()
                    fullMoveClock = Int(part) ?? 0
            } // switch
        } // for
    } // func
}
