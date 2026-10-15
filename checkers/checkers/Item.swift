//
//  Item.swift
//  checkers
//
//  Created by Hussein Helmy on 10/10/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
