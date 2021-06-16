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

enum FENParts {
    case piecePlacement([[Character]])
    case activeColor(TeamColor)
    case castlingAvailability([Character])
    case enpassantTarget(Position?)
    case halfmoveClock(Int?)
    case fullmoveClock(Int?)

    public static let parser: GenericParser<String, (), [FENParts?]> = {

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
        let placements =
            FENParts.piecePlacement <^> (pieces <|> emptySquares).many1.separatedBy1(char("/"))
            <* lexer.whiteSpace <?> "piece placement"

        // Active color
        // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
        //                                             ^
        let whiteColorActive = char("w") *> pure(TeamColor.white)
        let blackColorActive = char("b") *> pure(TeamColor.black)
        let activeTeamColor =
            FENParts.activeColor <^> (whiteColorActive <|> blackColorActive)
            <* lexer.whiteSpace <?> "team color"

        // Castling availability
        // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
        //                                               ^--^
        let castling =
            FENParts.castlingAvailability <^>
            (StringParser.oneOf("kqKQ").many1 <|> (char("-") *> pure(["-"])))
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
        let enpassantTarget = FENParts.enpassantTarget <^>
            (position <|>
                (char("-") *> pure(nil) ))
            <* lexer.whiteSpace.optional <?> "enpassant target"

        // Move clocks
        // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
        //                                                      ^-^
        let halfMove = FENParts.halfmoveClock <^>
            StringParser.digit.many1.stringValue.map { Int($0) }
            <* lexer.whiteSpace.optional <?> "half move clock"

        let fullMove = FENParts.fullmoveClock <^>
            StringParser.digit.many1.stringValue.map { Int($0) }
            <?> "full move clock"

        // Doesn't telegraph errors correctly
//        func createParts2<A>(_ lhs: A) -> (A) -> [A] {
//            return { rhs in return [lhs, rhs] }
//        }
//        return createParts2 <^> placements <*> activeTeamColor

//        func createParts3<A>(_ lhs: A) -> (A) -> (A) -> [A] {
//            { a in { b in [lhs, a, b] } }
//        }
//        return createParts3 <^> placements <*> activeTeamColor <*> castling

        // Parse
        return GenericParser.lift6({ [$0, $1, $2, $3, $4, $5] },
                                   parser1: placements,
                                   parser2: activeTeamColor,
                                   parser3: castling,
                                   parser4: enpassantTarget,
                                   parser5: halfMove.optional,
                                   parser6: fullMove.optional)
    }()

    public static func parse(data: String) throws -> [FENParts?] {
        return try Self.parser.run(sourceName: "", input: data)
//        Self.parser.runSafe(userState: , sourceName: , input: )
    }
}

/// Starting position FEN
/// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

func fenstrings() {

//    print(try! FENParts.parse(data: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))

    print(try! FENParts.parse(data: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))

}
