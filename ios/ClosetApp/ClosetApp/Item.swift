//
//  Item.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation

enum Category: String, Codable, CaseIterable {
    case top, bottom, shoes, outerwear, accessory
}

enum ItemStatus: String, Codable {
    case uploading, processing, ready, failed
}

struct Item: Codable, Identifiable, Hashable {
    let id: UUID
    let imageKey: String?
    let imageUrl: URL?
    var category: Category?
    var colors: [String]
    var styleTags: [String]
    let status: ItemStatus
    let createdAt: Date
}

// MARK: - Sample data for previews and Step 5

extension Item {
    static let samples: [Item] = [
        Item(id: UUID(), imageKey: nil, imageUrl: nil, category: .top,
             colors: ["white", "navy"], styleTags: ["casual"], status: .ready, createdAt: .now),
        Item(id: UUID(), imageKey: nil, imageUrl: nil, category: .bottom,
             colors: ["blue"], styleTags: ["casual"], status: .ready, createdAt: .now),
        Item(id: UUID(), imageKey: nil, imageUrl: nil, category: .shoes,
             colors: ["white"], styleTags: ["streetwear"], status: .ready, createdAt: .now),
        Item(id: UUID(), imageKey: nil, imageUrl: nil, category: .outerwear,
             colors: ["black"], styleTags: ["minimal"], status: .ready, createdAt: .now),
        Item(id: UUID(), imageKey: nil, imageUrl: nil, category: nil,
             colors: [], styleTags: [], status: .processing, createdAt: .now),
    ]
}
