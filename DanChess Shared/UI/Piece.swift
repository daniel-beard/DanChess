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
        let (pieceName, color) = pieceDesc(for: self)
        return "\(pieceName), \(color)"
    }

    let rawValue: Int
    typealias RawValue = Int

    static let pawn = Piece(rawValue: 1)
    static let rook = Piece(rawValue: 2)
    static let knight = Piece(rawValue: 3)
    static let bishop = Piece(rawValue: 4)
    static let queen = Piece(rawValue: 5)
    static let king = Piece(rawValue: 6)

    static let white = Piece(rawValue: 8)
    static let black = Piece(rawValue: 16)
}

enum Rank: Int {
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
        }
        return nil
    }

    static func +(rank: Rank, rhs: Int) -> Rank? {
        return Rank(rawValue: rank.rawValue + rhs)
    }
    static func -(rank: Rank, rhs: Int) -> Rank? {
        return Rank(rawValue: rank.rawValue - rhs)
    }
}

enum File: Int {
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

    static func +(file: File, rhs: Int) -> File? {
        return File(rawValue: file.rawValue + rhs)
    }
    static func -(file: File, rhs: Int) -> File? {
        return File(rawValue: file.rawValue - rhs)
    }
}

enum TeamColor: Int {
    case white = 8
    case black = 16
}

func pieceDesc(for piece: Piece) -> (pieceName: String, color: String) {
    var pieceName = ""
    var color = ""
    if piece.contains(.white) { color = "White" }
    if piece.contains(.black) { color = "Black" }
    if piece.contains(.pawn) { pieceName = "Pawn" }
    if piece.contains(.rook) { pieceName = "Rook" }
    if piece.contains(.knight) { pieceName = "Knight" }
    if piece.contains(.bishop) { pieceName = "Bishop" }
    if piece.contains(.queen) { pieceName = "Queen" }
    if piece.contains(.king) { pieceName = "King" }
    return (pieceName, color)
}

func pieceSprite(for piece: Piece) -> SKSpriteNode? {
    let (pieceName, color) = pieceDesc(for: piece)
    return SKSpriteNode(imageNamed: "\(pieceName)\(color)")
}
