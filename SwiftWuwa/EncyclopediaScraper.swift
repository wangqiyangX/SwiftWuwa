import Foundation
import OSLog
import SwiftSoup

/// EncyclopediaScraper for fetching character previews from the wiki catalogue
class EncyclopediaScraper {
    static let shared = EncyclopediaScraper()

    private let scraper: WebScraper<[EncyclopediaPreviewItem]>

    private init() {
        // Define the parsing strategy for character previews
        self.scraper = WebScraper(
            category: "EncyclopediaScraper",
            renderDelay: 3.0
        ) { doc, logger in
            let elements = try doc.select("div.entry-wrapper")
            var previews: [EncyclopediaPreviewItem] = []

            for element in elements {
                logger.debug("Parsing element: \(element)")

                // Name: div.card-footer-inner
                let name = (try? element.select("div.card-footer-inner").text()) ?? "Unknown"

                // Extract item ID from href using regex
                // Example: "/mc/item/1429457793942482944?wkFrom=..." -> "1429457793942482944"
                let hrefValue = try element.select("a").attr("href")
                let itemId: String
                if let match = hrefValue.range(of: #"/mc/item/(\d+)"#, options: .regularExpression),
                    let idRange = hrefValue.range(
                        of: #"\d+"#, options: .regularExpression, range: match)
                {
                    itemId = String(hrefValue[idRange])
                } else {
                    itemId = hrefValue  // Fallback to full href if regex fails
                }

                // Skill Attr: div.card-skill-attr-icon > img
                let skillAttrStr = try? element.select("div.card-skill-attr-icon > img").attr("src")
                let skillAttrURL = skillAttrStr.flatMap { $0.isEmpty ? nil : URL(string: $0) }

                // Image: div.card-content-inner > img
                let imgUrlStr = try? element.select("div.card-content-inner > img").attr("data-src")
                let imageURL = imgUrlStr.flatMap { $0.isEmpty ? nil : URL(string: $0) }

                previews.append(
                    EncyclopediaPreviewItem(
                        name: name,
                        itemId: itemId,
                        skillAttrURL: skillAttrURL,
                        imageURL: imageURL
                    )
                )
            }

            return previews
        }
    }

    /// Fetch entries from the wiki catalogue for a specific category
    /// - Parameters:
    ///   - category: The catalogue category to fetch
    ///   - forceRefresh: If true, bypass cache and fetch fresh data. Default is false.
    ///   - completion: Completion handler with parsed results
    func fetchEntries(
        category: EncyclopediaCategory,
        forceRefresh: Bool = false,
        completion: @escaping ([EncyclopediaPreviewItem]) -> Void
    ) {
        let url = category.buildURL()
        scraper.fetch(from: url, forceRefresh: forceRefresh, completion: completion)
    }

    /// Clear cached character data
    func clearCache() {
        scraper.clearCache()
    }
}
