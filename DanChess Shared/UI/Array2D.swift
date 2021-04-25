//
//  Array2D.swift
//  DanChess
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation

class Array2D<T> {

    var cols:Int, rows:Int
    var matrix:[T?]

    init(cols: Int, rows: Int, defaultValues:T?) {
        self.cols = cols
        self.rows = rows
        matrix = Array(repeating: defaultValues, count: cols*rows)
    }

    subscript(col:Int, row:Int) -> T? {
        get{
            return matrix[cols * row + col]
        }
        set{
            matrix[cols * row + col] = newValue
        }
    }

    subscript(col: Int32, row: Int32) -> T? {
        get{
            return matrix[cols * Int(row) + Int(col)]
        }
        set{
            matrix[cols * Int(row) + Int(col)] = newValue
        }
    }

    subscript(rank: Rank, file: File) -> T? {
        get{
            let idx = cols * Int(rank.rawValue - 1) + Int(file.rawValue - 1)
            return matrix[idx]
        }
        set{
            let idx = (cols * Int(rank.rawValue - 1) + Int(file.rawValue - 1))
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

    func colCount() -> Int { self.cols }
    func rowCount() -> Int { self.rows }

    func index(col: Int, row: Int) -> Int {
        return cols * row + col
    }

    func index(_ index: Int) -> (Int, Int) {
        return (index % cols, index / rows)
    }
}
