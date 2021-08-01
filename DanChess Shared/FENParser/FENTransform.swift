//
//  FENTransform.swift
//  DanChess
//
//  Created by Daniel Beard on 8/1/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation

///  This file takes the raw output from the parser and transforms into usable data structures we can directly send to the BoardNode class.
///  The parser does some basic constraint checking, but this file is responsible for transforming things like:
///     Raw Character piece placements -> 2D Array
///  As well as validating that the input FEN is valid for use.

enum FENError: Error {
    case placementTransform(String)
}

// The values here go from:
// Files: a -> h
// Ranks: 8 -> 1
// We move along each of the files, until we hit a '/' character, which increments the rank
// White pieces are uppercase, black pieces lowercase
//    rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
func placementsFromChars(_ chars: [[Character]]) throws -> Array2D<Piece> {
    let pieces = Array2D<Piece>(size: 8, defaultValues: nil)
    var rank = Rank.eight
    var file = File.a

    let charArray = Array(chars.joined(separator: "/"))
    for ch in charArray {
        if ch == "/" {
            let nextRankRawValue = rank.rawValue - 1
            guard let nextRank = Rank(rawValue: nextRankRawValue) else {
                throw FENError.placementTransform("Invalid rank value \(nextRankRawValue). Current char: \(ch) parts: \(charArray)")
            }
            rank = nextRank
            file = .a
            continue
        }
        if ch.isNumber {
            guard let intFromChar = Int(String(ch)) else {
                throw FENError.placementTransform("Could not transform character '\(ch)' to integer")
            }
            let nextFileRawValue = file.rawValue + (intFromChar - 1)
            guard let nextFile = File(rawValue: nextFileRawValue) else {
                throw FENError.placementTransform("Invalid next file value: \(nextFileRawValue). Current char: \(ch) parts: \(charArray)")
            }
            file = nextFile
            continue
        }
        // If we get here, it's a piece value
        let piece = Piece.fromFen(char: ch)
        pieces[rank, file] = piece

        file = File(rawValue: file.rawValue + 1) ?? .a
    }
    return pieces
}

//TODO: Validation stuff:

/**
Board:

There are exactly 8 ranks (rows).
The sum of the empty squares and pieces add to 8 for each rank (row).
There are no consecutive numbers for empty squares.
Kings:

See if there is exactly one w_king and one b_king.
Make sure kings are separated 1 square apart.
Checks:

Non-active color is not in check.
Active color is checked less than 3 times (triple check is impossible); in case of 2 that it is never pawn+(pawn, bishop, knight), bishop+bishop, knight+knight.
Pawns:

There are no more than 8 pawns from each color.
There aren't any pawns in first or last rank (row) since they're either in a wrong start position or they should have promoted.
In case of en passant square; see if it was legally created (e.g it must be on the x3 or x6 rank, there must be a pawn (from the correct color) in front of it, and the en passant square and the one behind it are empty).
Prevent having more promoted pieces than missing pawns (e.g extra_pieces = Math.max(0, num_queens-1) + Math.max(0, num_rooks-2) + Math.max(0, num_knights-2) + Math.max(0, num_bishops-2) and then extra_pieces <= (8-num_pawns)). A bit more processing-intensive is to count the light squared bishops and dark squared bishops separately, then do Math.max(0, num_lightsquared_bishops-1) and Math.max(0, num_darksquared_bishops-1). Another thing worth mentioning is that, whenever the extra_pieces is not 0, the other side must have less than 16 pieces because for a pawn to promote it needs to walk past another pawn in front and that can only happen if the pawn goes missing (taken or playing with a handicap) or the pawn shifts its file (column), in both cases decreasing the total of 16 pieces for the other side.
The pawn formation is possible to reach (e.g in case of multiple pawns in a single col, there must be enough enemy pieces missing to make that formation), here are some useful rules:
it is impossible to have more than 6 pawns in a single file (column) (because pawns can't exist in the first and last ranks).
the minimum number of enemy missing pieces to reach a multiple pawn in a single col B to G 2=1, 3=2, 4=4, 5=6, 6=9 ___ A and H 2=1, 3=3, 4=6, 5=10, 6=15, for example, if you see 5 pawns in A or H, the other player must be missing at least 10 pieces from his 15 captureable pieces.
if there are white pawns in a2 and a3, there can't legally be one in b2, and this idea can be further expanded to cover more possibilities.
Castling:

If the king or rooks are not in their starting position; the castling ability for that side is lost (in the case of king, both are lost).
Bishops:

Look for bishops in the first and last ranks (rows) trapped by pawns that haven't moved, for example:
a bishop (any color) trapped behind 3 pawns.
a bishop trapped behind 2 non-enemy pawns (not by enemy pawns because we can reach that position by underpromoting pawns, however if we check the number of pawns and extra_pieces we could determine if this case is possible or not).
Non-jumpers:

(Avoid this if you want to validate Fisher's Chess960) If there are non-jumpers enemy pieces in between the king and rook and there are still some pawns without moving; check if these enemy pieces could have legally gotten in there. Also, ask yourself: was the king or rook needed to move to generate that position? (if yes, we need to make sure the castling abilities reflect this).
If all 8 pawns are still in the starting position, all the non-jumpers must not have left their initial rank (also non-jumpers enemy pieces can't possibly have entered legally), there are other similar ideas, like if the white h-pawn moved once, the rooks should still be trapped inside the pawn formation, etc.
Half/Full move Clocks:

In case of an en passant square, the half move clock must equal to 0.
HalfMoves <= ((FullMoves-1)*2)+(if BlackToMove 1 else 0), the +1 or +0 depends on the side to move.
The HalfMoves must be x >= 0 and the FullMoves x >= 1.
If the HalfMove clock indicates that some reversible moves were played and you can't find any combination of reversible moves that could have produced this amount of Halfmoves (taking castling rights into account, forced moves, etc), example: a side with many pawns and a king with castling rights and a rook (the HalfMove clock should not have been able to increase for this side).
Other:

Make sure the FEN contains all the parts that are needed (e.g active color, castling ability, en passant square, etc).
Note: there is no need to make the 'players should not have more than 16 pieces' check because the points 'no more than 8 pawns' + 'prevent extra promoted pieces' + the 'exactly one king' should already cover this point.

Ref: https://chess.stackexchange.com/questions/1482/how-do-you-know-when-a-fen-position-is-legal
*/
