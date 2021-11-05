//
//  FENStrings.swift
//  DanChess
//
//  Created by Daniel Beard on 6/6/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation
import SwiftParsec

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

func pure<A>(_ result: A) -> GenericParser<String, (), A> { GenericParser(result: result) }

public struct FENParts {
    //MARK: Raw parser values
    let piecePlacement: [[Character]]
    let activeColor: TeamColor
    let castlingAvailability: [Character]
    let enpassantTarget: Position?
    let halfmoveClock: Int?
    let fullmoveClock: Int?

    //MARK: Transformed values
    var transformedPieces: Array2D<Piece>?
    var whiteCanCastleQueenside = false
    var whiteCanCastleKingside = false
    var blackCanCastleQueenside = false
    var blackCanCastleKingside = false
}

public let FENParser: GenericParser<String, (), FENParts> = {

    // Definitions + Setup
    let fen = LanguageDefinition<()>.empty
    let lexer = GenericTokenParser(languageDefinition: fen)
    let symbol = lexer.symbol
    let char = StringParser.character

    // Piece placements
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    // ^-----------------------------------------^
    let pieces = StringParser.oneOf("RrNnBbQqKkpP")
    let emptySquares = StringParser.oneOf("1"..."8")
    let placements = (pieces <|> emptySquares).many1.separatedBy1(char("/"))
    <* lexer.whiteSpace <?> "piece placement"

    // Active color
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    //                                             ^
    let whiteColorActive = char("w") *> pure(TeamColor.white)
    let blackColorActive = char("b") *> pure(TeamColor.black)
    let activeTeamColor = (whiteColorActive <|> blackColorActive)
    <* lexer.whiteSpace <?> "team color"

    // Castling availability
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    //                                               ^--^
    let castling = (StringParser.oneOf("kqKQ").many1 <|> (char("-") *> pure(["-"])))
    <* lexer.whiteSpace <?> "castling availability"

    // Enpassant target
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    // e.g. e3                                            ^
    let rank = StringParser.oneOf("12345678")
    let file = StringParser.oneOf("abcdefgh")
    let position = file >>- { f in
        rank >>- { r in
            return pure(Position(Rank(String(r)), File(String(f))))
        }
    }
    let enpassantTarget = (position <|>
                           (char("-") *> pure(nil) ))
    <* lexer.whiteSpace.optional <?> "enpassant target"

    // Move clocks
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    //                                                      ^-^
    let halfMove = StringParser.digit.many1.stringValue.map { Int($0)! }
    <* lexer.whiteSpace.optional <?> "half move clock"

    let fullMove = StringParser.digit.many1.stringValue.map { Int($0)! }
    <?> "full move clock"

    // Parse
    return GenericParser.lift6({
        FENParts(piecePlacement: $0,
                 activeColor: $1,
                 castlingAvailability: $2,
                 enpassantTarget: $3,
                 halfmoveClock: $4,
                 fullmoveClock: $5)
    },
                               parser1: placements,
                               parser2: activeTeamColor,
                               parser3: castling,
                               parser4: enpassantTarget,
                               parser5: halfMove.optional,
                               parser6: fullMove.optional)
    }()

/// Starting position FEN
/// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

func fenstrings() {
    do {
        var fenParts = try FENParser.run(sourceName: "",
                                         input: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        try fenParts.transform()
        print("fenParts: \(fenParts)")
    } catch {
        print("Caught error: \(error)")
    }
}

