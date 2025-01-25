//
//  Constants.swift
//  DanChess
//
//  Created by Daniel Beard on 11/6/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation
import SpriteKit

// MARK: Piece movement offsets

// We use these to walk along rays & calculate attacking pieces
let rookOffsets     = [(1,0),(-1,0),(0,1),(0,-1)]
let knightOffsets   = [(-1,2),(1,2),(2,1),(2,-1),(1,-2),(-1,-2),(-2,-1),(-2,1)]
let bishopOffsets   = [(1,1),(1,-1),(-1,-1),(-1,1)]
let queenOffsets    = [(1,0),(1,1),(1,-1),(-1,0),(-1,1),(0,0),(0,1),(0,-1),(-1,-1)]
let kingOffsets     = [(1,0),(1,1),(1,-1),(-1,0),(-1,1),(0,0),(0,1),(0,-1),(-1,-1)]
let blackKingAttackingPawnOffsets = [(-1,-1),(-1,1)]
let whiteKingAttackingPawnOffsets = [(1,-1),(1,1)]

let validPiecePlacementChars = "RrNnBbQqKkpP"
let START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

// MARK: Colors

let boardSquareLight     = SKColor._dbcolor(red: 235/255, green: 235/255, blue: 185/255)
let boardSquareDark      = SKColor._dbcolor(red: 175/255, green: 135/255, blue: 105/255)
let promotionFillColor   = SKColor._dbcolor(red: 205/255, green: 87/255, blue: 87/255)
let promotionStrokeColor = SKColor._dbcolor(red: 0, green: 0, blue: 0)
let attackOverlayColor   = SKColor._dbcolor(red: 255/255, green: 165/255, blue: 0/255)
let moveOverlayColor     = SKColor._dbcolor(red: 190/255, green: 37/255, blue: 109/255)
