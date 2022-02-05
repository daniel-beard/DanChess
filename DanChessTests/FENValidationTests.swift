//
//  FENValidationTests.swift
//  DanChessTests
//
//  Created by Daniel Beard on 11/4/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import XCTest
@testable import DanChess

class FENValidationTests: XCTestCase {

    /// Must have exactly 8 ranks
    func testExtraRankThrows() {
        let fenWithExtraRank = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/8 w KQkq - 0 1"
        var fenParts = try! FENParser.run(sourceName: "", input: fenWithExtraRank)
        XCTAssertThrowsError(try fenParts.transform(), "expected throw") { error in
            XCTAssertEqual(error as! FENError, FENError.invalidRankCount("Invalid rank count, found: 9, expected: 8"))
        }
    }

    /// Can't have consecutive 'skip' numbers
    func testConsecutiveNumbersThrows() {
        let fenWithExtraRank = "rnbqkbnr/pppppppp/62/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        var fenParts = try! FENParser.run(sourceName: "", input: fenWithExtraRank)
        XCTAssertThrowsError(try fenParts.transform(), "expected throw") { error in
            XCTAssertEqual(error as! FENError, FENError.consecutiveNumbers("Unexpected consecutive number: 2"))
        }
    }

    /// Any row that doesn't have exactly 8 values should throw. Last row has 9.
    func testTooLargeRowCountThrows() {
        let fenWithExtraRank = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR1 w KQkq - 0 1"
        var fenParts = try! FENParser.run(sourceName: "", input: fenWithExtraRank)
        XCTAssertThrowsError(try fenParts.transform(), "expected throw") { error in
            XCTAssertEqual(error as! FENError, FENError.invalidRowCount("Invalid count for row, got: 9"))
        }
    }

    /// Any row that doesn't have exactly 8 values should throw. Second row has 6
    func testTooSmallRowCountThrows() {
        let fenWithExtraRank = "rnbqkbnr/pppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        var fenParts = try! FENParser.run(sourceName: "", input: fenWithExtraRank)
        XCTAssertThrowsError(try fenParts.transform(), "expected throw") { error in
            XCTAssertEqual(error as! FENError, FENError.invalidRowCount("Invalid count for row, got: 6"))
        }
    }
}
