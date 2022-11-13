//
//  BoardNode.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import SpriteKit

protocol BoardDelegate: AnyObject {
    func playerPromotingPawn(at: Position)
}

enum GameMode {
    case regular
    case promotion(Position)
}

struct Features {
    /// Overlay attacking pieces when a player is in check
    static let overlayAttacking = true
    /// Overlay possible moves for a selected piece
    static let overlayPossibleMoves = true
}

/// Board SKNode and game logic
class BoardNode: SKNode {

    private var squares = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    private var pieces = Array2D<Piece>(size: 8, defaultValues: nil)
    let squareSize: Int

    var gameMode: GameMode = .regular

    weak var delegate: BoardDelegate?

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
        print("FEN: \(fenForCurrentBoard())")
        overlayAttackingPiecesForCurrentBoard()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }

    private func setupSquares() {

        // just for testing
        fenstrings()

        for file in 0..<8 {
            for rank in 0..<8 {
                let square = SKShapeNode(rect:
                                            CGRect(x: file * squareSize,
                                                   y: rank * squareSize,
                                                   width: squareSize,
                                                   height: squareSize))
                square.fillColor = (file + rank) % 2 != 0 ? boardSquareLight : boardSquareDark
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
        CGPoint(x: (pos.file.rawValue - 1) * squareSize + squareSize / 2, y: (pos.rank.rawValue - 1) * squareSize + squareSize / 2)
    }

    private func overlaySprite(withName name: String) -> SKShapeNode {
        let square = SKShapeNode(rect: CGRect(origin: .zero, size: .of(squareSize)))
        square.name = name
        square.fillColor = moveOverlayColor
        square.isUserInteractionEnabled = false
        return square
    }

    private func removeExistingOverlays(ofName name: String) {
        enumerateChildNodes(withName: name) { (node, stop) in
            node.removeFromParent()
        }
        // reset overlays array
        squaresOverlay.matrix = squaresOverlay.matrix.map { maybeNode in
            maybeNode?.name == name ? maybeNode : nil
        }
    }

    private func removeAllOverlays() {
        for overlayNode in squaresOverlay.matrix {
            overlayNode?.removeFromParent()
        }
        squaresOverlay = Array2D<SKShapeNode>(size: 8, defaultValues: nil)
    }

    public func displayPossibleMoves(forPieceAt position: Position) {
        guard Features.overlayPossibleMoves else { return }
        let overlayName = "possibleMoveOverlay"

        removeExistingOverlays(ofName: overlayName)

        // if it's not this colors turn, skip generating the moves
        if pieces[position]?.color() != turn {
            return
        }

        let possibles = possibleMoves(forPieceAt: position)

        // add new overlays
        for p in possibles {
            let sprite = overlaySprite(withName: overlayName)
            sprite.position = CGPoint(x: (p.file.rawValue - 1) * squareSize,
                                      y: (p.rank.rawValue - 1) * squareSize)
            squaresOverlay[p] = sprite
            addChild(sprite)
        }
    }

    public func overlayAttackingPiecesForCurrentBoard() {
        guard Features.overlayAttacking else { return }
        let overlayName = "attackingPiecesOverlay"

        removeExistingOverlays(ofName: overlayName)

        let check = Self.inCheck(pieces: self.pieces, teamColor: self.turn)
        let overlayPositions = check.attackingPieces.isEmpty ? [] : check.attackingPieces.appending(check.king)
        for p in overlayPositions {
            let sprite = overlaySprite(withName: overlayName)
            sprite.fillColor = attackOverlayColor
            sprite.position = CGPoint(x: (p.file.rawValue - 1) * squareSize,
                                      y: (p.rank.rawValue - 1) * squareSize)
            squaresOverlay[p] = sprite
            addChild(sprite)
        }
    }

    public func canPickupPiece(at pos: Position) -> Bool {
        // Can't make any other moves while choosing a promotion piece
        if case .promotion(_) = gameMode { return false }
        return pieces[pos]?.color() == turn
    }

    public func canMove(from start: Position, to end: Position) -> Bool {
        let possibles = possibleMoves(forPieceAt: start)
        return possibles.contains(end)
    }

    public func removeNode(at position: Position?) {
        guard let position else { return }
        self.nodes(at: uiPosition(forBoardPosition: position))
            .filter { $0.name?.starts(with: "piece") ?? false }
            .forEach { $0.removeFromParent() }
    }

    public func replace(piece: Piece, at position: Position?) {
        guard let position else { return }
        // Remove existing piece
        pieces[position] = nil
        removeNode(at: position)

        // Insert chosen piece
        pieces[position] = piece
        let sprite = piece.sprite()
        sprite.name = piece.spriteName()
        sprite.zPosition = 300
        addChild(sprite)
        sprite.position = uiPosition(forBoardPosition: position)
    }

    // Calculate if the king is in check for a particular color and board node.
    // This lets us walk forward in time to check future moves.
    public class func inCheck(pieces: Array2D<Piece>, teamColor: TeamColor) -> CheckResult {
        // Find the king
        let kingColor = teamColor
        let kingPiece = Piece([.king, kingColor.toPieceColor()])
        let king = pieces.firstPosition(ofPiece: kingPiece)!

        // Attacking piece positions
        let attackingRooks = rookOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isRook(pieces[pos]) }
        let attackingKnights = knightOffsets
            .map { king.offset(by: $0.0, $0.1) }
            .filter { pos in
                guard let piece = pieces[pos] else { return false }
                return isKnight(pieces: pieces, pos) && piece.color() != kingColor
            }
        let attackingBishops = bishopOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isBishop(pieces[pos]) }
        let attackingQueens = queenOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1) }
            .compactMap { $0.last }.filter { pos in isQueen(pieces[pos]) }
        let attackingKings = kingOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1) }
            .compactMap { $0.last }.filter { pos in isKing(pieces[pos]) }
        let pawnOffsets = kingColor == .white ? whiteKingAttackingPawnOffsets : blackKingAttackingPawnOffsets
        let attackingPawns = pawnOffsets.map { ray(from: king, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1) }
            .compactMap { $0.last }.filter { pos in
                isPawn(pieces[pos])
            }

        let attackingPieces: [Position] = [attackingRooks, attackingKnights, attackingBishops, attackingQueens, attackingKings, attackingPawns]
            .flatMap { $0 }.compactMap { $0 }

        // Set to output debug logs
        let debugAttacking = false
        { debug in
            if debug {
                print("\(teamColor.stringValue) king is at: \(king)")
                print("Attacking rooks: \(attackingRooks)")
                print("Attacking knights: \(attackingKnights)")
                print("Attacking bishops: \(attackingBishops)")
                print("Attacking queens: \(attackingQueens)")
                print("Attacking kings: \(attackingKings)")
                print("=============================================")
            }
        }(debugAttacking)

        return CheckResult(teamColor: teamColor, inCheck: attackingPieces.count > 0, king: king, attackingPieces: attackingPieces)
    }

    public func choosePromotionPiece(_ piece: Piece)  {
        guard case .promotion(let position) = gameMode else { return }
        guard isKnight(piece)
                || isQueen(piece)
                || isBishop(piece)
                || isRook(piece) else {
            return
        }
        // Remove existing piece
        removeAllOverlays()
        removeNode(at: position)

        // Insert chosen piece
        replace(piece: piece, at: position)

        // Finally, we aren't promoting a piece any more
        gameMode = .regular
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
        removeAllOverlays()

        // Promotion
        if isPawn(piece) {
            switch (piece?.color(), end.rank) {
                case (.white, .eight): fallthrough
                case (.black, .one):
                    gameMode = .promotion(end)
                    removeNode(at: end)
                    delegate?.playerPromotingPawn(at: end)
                    return
                default: break
            }
        }

        // Set next turn, overlay check
        defer {
            turn = moveColor.toggle()
            overlayAttackingPiecesForCurrentBoard()
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
        let _ = Self.inCheck(pieces: pieces, teamColor: turn)
    }

    private func castleRookMove(start: Position, end: Position) {
        let rook = pieces[start]
        pieces[end] = rook
        pieces[start] = nil
        guard let node = nodes(at: uiPosition(forBoardPosition: start))
                .filter({ $0.name?.starts(with: "piece") ?? false }).first else { return }
        node.position = uiPosition(forBoardPosition: end)
    }

    public func playForward(startPosition: Position, move: Position, piece: Piece) -> Array2D<Piece> {
        var currPieces = self.pieces
        currPieces[move.rank, move.file] = piece
        currPieces[startPosition.rank, startPosition.file] = nil
        return currPieces
    }

    public func possibleMoves(forPieceAt pos: Position) -> [Position] {

        // Get the piece, if there isn't one, there are no moves to return
        guard let piece = pieces[pos] else { return [] }
        let white = piece.contains(.white)
        let currColor = piece.color()

        var moves = [Position?]()

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
        } else if piece.contains(.rook) {
            moves.append(contentsOf: rookOffsets.map {
                Self.ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
        } else if piece.contains(.knight) {
            moves.append(contentsOf: knightOffsets.map {
                if let next = pos.offset(by: $0.0, $0.1), pieces[next]?.color() != currColor {
                    return next
                }
                return nil
            })
        } else if piece.contains(.bishop) {
            moves.append(contentsOf: bishopOffsets.map {
                Self.ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
        } else if piece.contains(.queen) {
            moves.append(contentsOf: queenOffsets.map {
                Self.ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1)
            }.flatMap { $0 })
        } else if piece.contains(.king) {
            moves.append(contentsOf: kingOffsets.map {
                Self.ray(from: pos, in: pieces, rankOffset: $0.0, fileOffset: $0.1, maxLength: 1)
            }.flatMap{ $0 })
            // Handle castling
            // There's a special case here, we need to check the intermediate castling moves.
            // If an intermediate move is in check, then that castling operation is invalid.
            if turn == .white {
                let kingHome = Position(.one, .e)
                if pos == kingHome {
                    // Can castle queenside if no one on d1 or c1 and eligible
                    if whiteCanCastleQueenside && pieces[.one, .d] == nil && pieces[.one, .c] == nil {
                        let intermediate = Position(.one, .d)
                        if !Self.inCheck(
                                pieces: playForward(startPosition: pos, move: intermediate, piece: piece),
                                teamColor: currColor).inCheck {
                            moves.append(Position(.one, .c))
                        }
                    }
                    // Can castle kingside if no one on f1 or g1 and eligible
                    if whiteCanCastleKingside && pieces[.one, .f] == nil && pieces[.one, .g] == nil {
                        let intermediate = Position(.one, .f)
                        if !Self.inCheck(
                                pieces: playForward(startPosition: pos, move: intermediate, piece: piece),
                                teamColor: currColor).inCheck {
                            moves.append(Position(.one, .g))
                        }
                    }
                }
            } else {
                let kingHome = Position(.eight, .e)
                if pos == kingHome {
                    // Can castle queenside if no one on d8 or c8 and eligible
                    if blackCanCastleQueenside && pieces[.eight, .d] == nil && pieces[.eight, .c] == nil {
                        let intermediate = Position(.eight, .d)
                        if !Self.inCheck(
                                pieces: playForward(startPosition: pos, move: intermediate, piece: piece),
                                teamColor: currColor).inCheck {
                            moves.append(Position(.eight, .c))
                        }
                    }
                    // Can castle kingside if no one on f8 or g8 and eligible
                    if blackCanCastleKingside && pieces[.eight, .f] == nil && pieces[.eight, .g] == nil {
                        let intermediate = Position(.eight, .f)
                        if !Self.inCheck(
                                pieces: playForward(startPosition: pos, move: intermediate, piece: piece),
                                teamColor: currColor).inCheck {
                            moves.append(Position(.eight, .g))
                        }
                    }
                }
            }
        }

        // Remove nil moves
        let concreteMoves = moves.compactMap { $0 }

        // For each potential move, play it, see if that would take us into check
        // This doesn't handle the intermediate castling positions, those are handled above.
        var finalMoves = [Position]()
        for move in concreteMoves {
            let inCheck = Self.inCheck(
                pieces: playForward(startPosition: pos, move: move, piece: piece),
                teamColor: currColor).inCheck
            print("inCheck? \(move.rank) \(move.file) \(piece) - \(inCheck)")
            if !inCheck {
                finalMoves.append(move)
            }
        }
        return finalMoves
    }

    /** Returns potential moves as an array along a movement line 'offset'
        Will include an enemy player if this movement line leads to a taking move.

        @param from: The position to start searching. We calculate what our color is by looking up the piece at this position.
        @param in: The piece 2D array to read.
        @param rankOffset: rank component of the offset movement line we are walking.
        @param fileOffset: file component of the offset movement line we are walking.
        @param maxLength: Set to a smaller value to control the maximum movement line length
    */
    private class func ray(from position: Position, in pieceArray: Array2D<Piece>, rankOffset: Int, fileOffset: Int, maxLength: Int = Int.max) -> [Position?] {
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

    private func isRook(_ piece: Piece?)    -> Bool { Self.isRook(piece) }
    private func isRook(_ pos: Position?)   -> Bool { Self.isRook(pieces: self.pieces, pos) }
    private class func isRook(_ piece: Piece?)    -> Bool { piece?.contains(.rook) ?? false }
    private class func isRook(pieces: Array2D<Piece>, _ pos: Position?)   -> Bool { pieces[pos]?.contains(.rook) ?? false }

    private func isKnight(_ piece: Piece?)  -> Bool { Self.isKnight(piece) }
    private func isKnight(_ pos: Position?) -> Bool { Self.isKnight(pieces: self.pieces, pos) }
    private class func isKnight(_ piece: Piece?)  -> Bool { piece?.contains(.knight) ?? false }
    private class func isKnight(pieces: Array2D<Piece>, _ pos: Position?) -> Bool { pieces[pos]?.contains(.knight) ?? false }

    private func isBishop(_ piece: Piece?)  -> Bool { Self.isBishop(piece) }
    private func isBishop(_ pos: Position?) -> Bool { Self.isBishop(pieces: self.pieces, pos) }
    private class func isBishop(_ piece: Piece?)  -> Bool { piece?.contains(.bishop) ?? false }
    private class func isBishop(pieces: Array2D<Piece>, _ pos: Position?) -> Bool { pieces[pos]?.contains(.bishop) ?? false }

    private func isQueen(_ piece: Piece?)   -> Bool { Self.isQueen(piece) }
    private func isQueen(_ pos: Position?)  -> Bool { Self.isQueen(pieces: self.pieces, pos) }
    private class func isQueen(_ piece: Piece?)   -> Bool { piece?.contains(.queen) ?? false }
    private class func isQueen(pieces: Array2D<Piece>, _ pos: Position?)  -> Bool { pieces[pos]?.contains(.queen) ?? false }

    private func isKing(_ piece: Piece?)    -> Bool { Self.isKing(piece) }
    private func isKing(_ pos: Position?)   -> Bool { Self.isKing(pieces: self.pieces, pos)}
    private class func isKing(_ piece: Piece?)    -> Bool { piece?.contains(.king) ?? false }
    private class func isKing(pieces: Array2D<Piece>, _ pos: Position?)   -> Bool { pieces[pos]?.contains(.king) ?? false }

    private func isPawn(_ piece: Piece?)    -> Bool { Self.isPawn(piece) }
    private func isPawn(_ pos: Position?)   -> Bool { Self.isPawn(pieces: self.pieces, pos) }
    private class func isPawn(_ piece: Piece?)    -> Bool { piece?.contains(.pawn) ?? false }
    private class func isPawn(pieces: Array2D<Piece>, _ pos: Position?)   -> Bool { pieces[pos]?.contains(.pawn) ?? false }

    private func isEmpty(_ pos: Position?)  -> Bool { pieces[pos] == nil }
    private class func isEmpty(pieces: Array2D<Piece>, _ pos: Position?)  -> Bool { pieces[pos] == nil }

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
                    replace(piece: piece, at: Position(rank, file))

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
