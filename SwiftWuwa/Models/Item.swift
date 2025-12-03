//
//  Item.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String?
    var imageURL: URL?
    var itemId: String?
    var tabType: String
    var subType: String

    init(
        id: UUID = UUID(),
        name: String? = nil,
        imageURL: URL? = nil,
        itemId: String? = nil,
        tabType: String,
        subType: String
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.itemId = itemId
        self.tabType = tabType
        self.subType = subType
    }
}
