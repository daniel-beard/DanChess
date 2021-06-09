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

func just<A>(_ result: A) -> GenericParser<String, (), A> { GenericParser(result: result) }

enum FENParts {
    case piecePlacement([[Character]])
    case activeColor(TeamColor)
    case castlingAvailability([Character])
    case enpassantTarget
    case halfmoveClock(Int?)
    case fullmoveClock(Int?)

    public static let parser: GenericParser<String, (), [FENParts]> = {

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
        let whiteColorActive = symbol("w") *> GenericParser(result: TeamColor.white)
        let blackColorActive = symbol("b") *> GenericParser(result: TeamColor.black)
        let activeTeamColor =
            FENParts.activeColor <^> (whiteColorActive <|> blackColorActive)
            <* lexer.whiteSpace <?> "team color"

        // Castling availability
        // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
        //                                               ^--^
        let castling =
            FENParts.castlingAvailability <^>
            (StringParser.oneOf("kqKQ").many <|> (symbol("-") *> GenericParser(result: ["-"])))

        var result = [FENParts]()

        return GenericParser.lift3({ [$0, $1, $2] }, parser1: placements, parser2: activeTeamColor, parser3: castling)
    }()

    public static func parse(data: String) throws -> [FENParts] {
        return try Self.parser.run(sourceName: "", input: data)
//        Self.parser.runSafe(userState: , sourceName: , input: )
    }
}

/// Starting position FEN
/// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

func fenstrings() {

    print(try! FENParts.parse(data: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))

    print(try! FENParts.parse(data: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))

}
