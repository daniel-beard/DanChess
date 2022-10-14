//
//  Array2D.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation

struct Array2D<T: Equatable> {

    // Size in one dimension. E.g. size = 8 implies a 2D array of 8x8
    var size: Int
    var matrix:[T?]

    init(size: Int, defaultValues:T?) {
        self.size = size
        matrix = Array(repeating: defaultValues, count: size*size)
    }

    subscript(col:Int, row:Int) -> T? {
        get{
            return matrix[size * row + col]
        }
        set{
            matrix[size * row + col] = newValue
        }
    }

    subscript(col: Int32, row: Int32) -> T? {
        get{
            return matrix[size * Int(row) + Int(col)]
        }
        set{
            matrix[size * Int(row) + Int(col)] = newValue
        }
    }

    subscript(rank: Rank, file: File) -> T? {
        get{
            let idx = size * Int(rank.rawValue - 1) + Int(file.rawValue - 1)
            return matrix[idx]
        }
        set{
            let idx = (size * Int(rank.rawValue - 1) + Int(file.rawValue - 1))
            matrix[idx] = newValue
        }
    }

    subscript(p: Position) -> T? {
        get{
            let idx = size * Int(p.rank.rawValue - 1) + Int(p.file.rawValue - 1)
            return matrix[idx]
        }
        set{
            let idx = (size * Int(p.rank.rawValue - 1) + Int(p.file.rawValue - 1))
            matrix[idx] = newValue
        }
    }

    subscript(p: Position?) -> T? {
        get {
            if let p = p { return self[p] }
            return nil
        }
        set {
            if let p = p { self[p] = newValue }
        }
    }

    subscript(index: Int) -> T? {
        get{
            return matrix[index]
        }
        set{
            matrix[index] = newValue
        }
    }

    func positionToIndex(position: Position) -> Int {
        let idx = size * Int(position.rank.rawValue - 1) + Int(position.file.rawValue - 1)
        return idx
    }

    // Filter the board for a particular piece. Returns nil, or a position.
    // Returns only the first match.
    func firstPosition(ofPiece piece: T) -> Position? {
        guard let idx = matrix.firstIndex(where: { $0 == piece }) else { return nil }
        return position(fromIndex: idx)
    }

    // Return positions of all pieces matching a condition
    func allPositions(matching: (T) -> Bool) -> [Position] {
        var positions = [Position]()
        for (idx, piece) in matrix.enumerated() {
            guard let piece = piece else { continue }
            guard matching(piece) else { continue }
            guard let position = position(fromIndex: idx) else { continue }
            positions.append(position)
        }
        return positions
    }

    func collect(_ p: Position?...) -> [T?] {
        var result = [T?]()
        for pos in p {
            result.append(self[pos])
        }
        return result
    }

    func colCount() -> Int { size }
    func rowCount() -> Int { size }

    func position(fromIndex idx: Int) -> Position? {
        guard idx >= 0 && idx <= matrix.count else { return nil }
        let pair = index(idx)
        return Position(Rank(rawValue: pair.1+1), File(rawValue: pair.0+1))
    }

    func index(col: Int, row: Int) -> Int {
        return size * row + col
    }

    func index(_ index: Int) -> (Int, Int) {
        return (index % size, index / size)
    }
}
