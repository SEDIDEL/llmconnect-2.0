//
//  Item.swift
//  LLMConnect2.0
//
//  Created by Sebastian Diaz on 10/05/25.
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
