//
//  Constants.swift
//  DanChess
//
//  Created by Daniel Beard on 11/6/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation

// Piece movement offsets:
// We use these to walk along rays
let rookOffsets     = [(1,0),(-1,0),(0,1),(0,-1)]
let knightOffsets   = [(-1,2),(1,2),(2,1),(2,-1),(1,-2),(-1,-2),(-2,-1),(-2,1)]
let bishopOffsets   = [(1,1),(1,-1),(-1,-1),(-1,1)]
let queenOffsets    = [(1,0),(1,1),(1,-1),(-1,0),(-1,1),(0,0),(0,1),(0,-1),(-1,-1)]
let kingOffsets     = [(1,0),(1,1),(1,-1),(-1,0),(-1,1),(0,0),(0,1),(0,-1),(-1,-1)]
let blackKingAttackingPawnOffsets = [(-1,-1),(-1,1)]
let whiteKingAttackingPawnOffsets = [(1,-1),(1,1)]

let validPiecePlacementChars = "RrNnBbQqKkpP"
