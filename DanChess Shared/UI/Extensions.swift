//
//  Extensions.swift
//  DanChess
//
//  Created by Daniel Beard on 4/25/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import Foundation
import SpriteKit

extension CGSize {
    init(of size: Int) {
        self.init(width: size, height: size)
    }
    static func of(_ size: Int) -> CGSize {
        return CGSize(of: size)
    }
}
