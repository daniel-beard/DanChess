//
//  Piece.swift
//  DanChess
//
//  Created by Daniel Beard on 4/24/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation
import SpriteKit

struct Piece: OptionSet, CustomDebugStringConvertible {
    var debugDescription: String {
        let (pieceName, color) = pieceDesc()
        return "\(pieceName), \(color)"
    }

    let rawValue: Int
    typealias RawValue = Int

    static let pawn = Piece(rawValue: 1)
    static let rook = Piece(rawValue: 1 << 2)
    static let knight = Piece(rawValue: 1 << 3)
    static let bishop = Piece(rawValue: 1 << 4)
    static let queen = Piece(rawValue: 1 << 5)
    static let king = Piece(rawValue: 1 << 6)

    static let white = Piece(rawValue: 1 << 7)
    static let black = Piece(rawValue: 1 << 8)

    func color() -> TeamColor { self.contains(.white) ? .white : .black }

    static func fromFen(char: Character) -> Piece? {
        let color = char.isUppercase ? white : black
        let piece: Piece
        switch char.lowercased() {
            case "p": piece = .pawn
            case "r": piece = .rook
            case "n": piece = .knight
            case "b": piece = .bishop
            case "q": piece = .queen
            case "k": piece = .king
            default: return nil
        }
        return [piece, color]
    }

    var algebraicNotation: String {
        var result = ""
        if self.contains(.pawn)         { result = "p" }
        else if self.contains(.rook)    { result = "r" }
        else if self.contains(.knight)  { result = "n" }
        else if self.contains(.bishop)  { result = "b" }
        else if self.contains(.queen)   { result = "q" }
        else if self.contains(.king)    { result = "k" }
        return color() == .white ? result.uppercased() : result
    }

    func pieceDesc() -> (pieceName: String, color: String) {
        var pieceName = ""
        var color = ""
        if contains(.white)   { color = "White" }
        if contains(.black)   { color = "Black" }
        if contains(.pawn)    { pieceName = "Pawn" }
        if contains(.rook)    { pieceName = "Rook" }
        if contains(.knight)  { pieceName = "Knight" }
        if contains(.bishop)  { pieceName = "Bishop" }
        if contains(.queen)   { pieceName = "Queen" }
        if contains(.king)    { pieceName = "King" }
        return (pieceName, color)
    }

    func sprite() -> SKSpriteNode {
        let (pieceName, color) = pieceDesc()
        return SKSpriteNode(imageNamed: "\(pieceName)\(color)")
    }

    func spriteName() -> String {
        let (pieceName, color) = pieceDesc()
        return "piece:\(pieceName)\(color)"
    }
}

enum Rank: Int, CustomDebugStringConvertible, CaseIterable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight

    init?(_ string: String) {
        guard string.count == 1 else { fatalError("Init with string only takes a single character") }
        if let raw = Int(string), let rank = Rank(rawValue: raw) {
            self = rank
        } else {
            return nil
        }
    }

    var algebraicNotation: String { "\(rawValue)" }
    var debugDescription: String { algebraicNotation }

    static func +(rank: Rank, rhs: Int) -> Rank? {
        return Rank(rawValue: rank.rawValue + rhs)
    }
    static func -(rank: Rank, rhs: Int) -> Rank? {
        return Rank(rawValue: rank.rawValue - rhs)
    }
}

enum File: Int, CustomDebugStringConvertible, CaseIterable {

    case a = 1
    case b
    case c
    case d
    case e
    case f
    case g
    case h

    init?(_ string: String) {
        guard string.count == 1 else { fatalError("Init with string only takes a single character") }
        switch string {
            case "a": self = .a
            case "b": self = .b
            case "c": self = .c
            case "d": self = .d
            case "e": self = .e
            case "f": self = .f
            case "g": self = .g
            case "h": self = .h
            default: return nil
        }
    }

    var algebraicNotation: String {
        switch self {
            case .a: return "a"
            case .b: return "b"
            case .c: return "c"
            case .d: return "d"
            case .e: return "e"
            case .f: return "f"
            case .g: return "g"
            case .h: return "h"
        }
    }

    var debugDescription: String { algebraicNotation }

    static func +(file: File, rhs: Int) -> File? {
        return File(rawValue: file.rawValue + rhs)
    }
    static func -(file: File, rhs: Int) -> File? {
        return File(rawValue: file.rawValue - rhs)
    }
}

enum TeamColor: Int {
    case white = 128
    case black = 256

    var stringValue: String {
        switch self {
            case .white: return "White"
            case .black: return "Black"
        }
    }

    func toPieceColor() -> Piece {
        self == .white ? Piece.white : Piece.black
    }

    func toggle() -> TeamColor {
        return self == .white ? .black : .white
    }
}

struct Position: Equatable {
    let rank: Rank
    let file: File

    init(nonOptionalRank: Rank, nonOptionalFile: File) {
        self.rank = nonOptionalRank
        self.file = nonOptionalFile
    }

    init(_ rank: Rank, _ file: File) {
        self.rank = rank
        self.file = file
    }

    init?(_ rank: Rank?, _ file: File?) {
        guard let rank = rank, let file = file else { return nil }
        self.rank = rank
        self.file = file
    }

    static func fromFen(string: String) -> Position? {
        guard string.count == 2 else { return nil }
        guard string != "-" else { return nil }
        let rank = String(string.first!)
        let file = String(string.last!)
        return Position(Rank(rank), File(file))
    }

    func toFen() -> String {
        "\(rank.algebraicNotation)\(file.algebraicNotation)"
    }

    // Create new position by adding offsets to current rank & file values.
    // Returns nil if the position is not valid for rank or file.
    func offset(by r: Int, _ f: Int) -> Position? {
        if let newRank = Rank(rawValue: rank.rawValue + r), let newFile = File(rawValue: file.rawValue + f) {
            return Position(newRank, newFile)
        }
        return nil
    }
}

/// Data about a check
struct CheckResult {
    /// Team color that was checked for check
    var teamColor: TeamColor
    /// Whether the teamColor is in check
    var inCheck: Bool
    /// Position of the attacked king
    var king: Position
    /// Positions of all pieces causing the check
    var attackingPieces: [Position]
}
