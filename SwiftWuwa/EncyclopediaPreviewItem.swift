import Foundation

struct EncyclopediaPreviewItem: Identifiable {
    let id = UUID()
    let name: String
    let itemId: String
    let skillAttrURL: URL?
    let imageURL: URL?
}

