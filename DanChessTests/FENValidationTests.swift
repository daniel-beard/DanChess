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

    func testExtraRankThrows() {
        let fenWithExtraRank = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/8 w KQkq - 0 1"
        var fenParts = try! FENParser.run(sourceName: "", input: fenWithExtraRank)
        XCTAssertThrowsError(try fenParts.transform(), "expected throw") { error in
            XCTAssertEqual(error as! FENError, FENError.invalidRankCount("Invalid rank count, found: 9, expected: 8"))
        }
    }
}
