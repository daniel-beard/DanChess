//
//  Array2D.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation

class Array2D<T> {

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

    subscript(index: Int) -> T? {
        get{
            return matrix[index]
        }
        set{
            matrix[index] = newValue
        }
    }

    func colCount() -> Int { size }
    func rowCount() -> Int { size }

    func index(col: Int, row: Int) -> Int {
        return size * row + col
    }

    func index(_ index: Int) -> (Int, Int) {
        return (index % size, index / size)
    }
}
