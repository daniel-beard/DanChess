//
//  Extensions.swift
//  DanChess
//
//  Created by Daniel Beard on 4/25/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation
import SpriteKit
import SwiftParsec

extension CGSize {
    init(of size: Int) {
        self.init(width: size, height: size)
    }
    static func of(_ size: Int) -> CGSize {
        return CGSize(of: size)
    }
}

extension SKColor {
    /// Platform agnostic color init method
    class func _dbcolor(red: CGFloat, green: CGFloat, blue: CGFloat) -> SKColor {
        #if os(macOS)
            return SKColor(deviceRed: red, green: green, blue: blue, alpha: 1)
        #else
            return SKColor(red: red, green: green, blue: blue, alpha: 1)
        #endif
    }
}

extension GenericParser {
    /// Return a parser that applies the result of the supplied parsers to the
    /// lifted function. The parsers are applied from left to right.
    ///
    /// - parameters:
    ///   - function: The function to lift into the parser.
    ///   - parser1: The parser returning the first argument passed to the
    ///     lifted function.
    ///   - parser2: The parser returning the second argument passed to the
    ///     lifted function.
    ///   - parser3: The parser returning the third argument passed to the
    ///     lifted function.
    ///   - parser4: The parser returning the fourth argument passed to the
    ///     lifted function.
    ///   - parser5: The parser returning the fifth argument passed to the
    ///     lifted function.
    ///   - parser6: The parser returning the sixth argument passed to the
    ///     lifted function.
    /// - returns: A parser that applies the result of the supplied parsers to
    ///   the lifted function.
    public static func lift6<Param1, Param2, Param3, Param4, Param5, Param6>(
        _ function: @escaping (Param1, Param2, Param3, Param4, Param5, Param6) -> Result,
        parser1: GenericParser<StreamType, UserState, Param1>,
        parser2: GenericParser<StreamType, UserState, Param2>,
        parser3: GenericParser<StreamType, UserState, Param3>,
        parser4: GenericParser<StreamType, UserState, Param4>,
        parser5: GenericParser<StreamType, UserState, Param5>,
        parser6: GenericParser<StreamType, UserState, Param6>
    ) -> GenericParser {

        return parser1 >>- { result1 in
            parser2 >>- { result2 in
                parser3 >>- { result3 in
                    parser4 >>- { result4 in
                        parser5 >>- { result5 in
                            parser6 >>- { result6 in
                                let combinedResult = function(
                                    result1,
                                    result2,
                                    result3,
                                    result4,
                                    result5,
                                    result6
                                )
                                return GenericParser(result: combinedResult)
                            }
                        }
                    }
                }
            }
        }
    }
}
