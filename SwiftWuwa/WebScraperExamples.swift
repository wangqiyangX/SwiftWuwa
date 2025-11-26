import Foundation
import SwiftSoup

// MARK: - Example Usage of Generic WebScraper (Updated)

/*
 The WebScraper class is now truly generic and supports ANY return type T.
 You can return:
 - Single objects (CharacterDetail)
 - Arrays ([CharacterPreview])
 - Tuples, structs, or any custom type
 */

// MARK: - Example 1: Array Return Type (List of Items)

struct WeaponPreview: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let imageURL: URL?
}

class WeaponScraper {
    static let shared = WeaponScraper()

    // WebScraper<[WeaponPreview]> - returns an array
    private let scraper: WebScraper<[WeaponPreview]>
    private let weaponsURL = URL(
        string: "https://wiki.kurobbs.com/mc/catalogue/list?fid=1099&sid=1106"
    )!

    private init() {
        self.scraper = WebScraper(
            category: "WeaponScraper",
            renderDelay: 3.0
        ) { doc, logger in
            // Parse strategy returns [WeaponPreview]
            let elements = try doc.select("div.weapon-card")
            var weapons: [WeaponPreview] = []

            for element in elements {
                let name =
                    (try? element.select(".weapon-name").text()) ?? "Unknown"
                let type =
                    (try? element.select(".weapon-type").text()) ?? "Unknown"
                let imgStr = try? element.select("img").attr("src")
                let imageURL = imgStr.flatMap { URL(string: $0) }

                weapons.append(
                    WeaponPreview(name: name, type: type, imageURL: imageURL)
                )
            }

            return weapons  // Returns array
        }
    }

    func fetchWeapons(
        forceRefresh: Bool = false,
        completion: @escaping ([WeaponPreview]) -> Void
    ) {
        scraper.fetch(
            from: weaponsURL,
            forceRefresh: forceRefresh,
            completion: completion
        )
    }
}

// MARK: - Example 2: Single Object Return Type (Detail View)

struct ExampleCharacterDetail {
    struct Info {
        let name: String?
        let description: String?
        let rarity: Int?
        let element: String?
    }

    let info: Info
    let skills: [String]
    let stats: [String: Int]
}

class ExampleCharacterDetailScraper {
    static let shared = ExampleCharacterDetailScraper()

    // WebScraper<ExampleCharacterDetail> - returns a single object
    private let scraper: WebScraper<ExampleCharacterDetail>

    private init() {
        self.scraper = WebScraper(
            category: "ExampleCharacterDetailScraper",
            renderDelay: 5.0
        ) { doc, logger in
            // Parse strategy returns ExampleCharacterDetail (single object)
            let name = try? doc.select("div.main-info div.name").text()
            let description = try? doc.select("div.main-info div.description")
                .text()
            let rarityStr = try? doc.select("div.rarity").text()
            let rarity = Int(rarityStr ?? "")
            let element = try? doc.select("div.element").text()

            let skillElements = try doc.select("div.skill-item")
            let skills = skillElements.compactMap { try? $0.text() }

            var stats: [String: Int] = [:]
            let statElements = try doc.select("div.stat-item")
            for statElement in statElements {
                if let key = try? statElement.select(".stat-name").text(),
                    let valueStr = try? statElement.select(".stat-value")
                        .text(),
                    let value = Int(valueStr)
                {
                    stats[key] = value
                }
            }

            return ExampleCharacterDetail(
                info: .init(
                    name: name,
                    description: description,
                    rarity: rarity,
                    element: element
                ),
                skills: skills,
                stats: stats
            )  // Returns single object
        }
    }

    func fetchDetails(
        from url: URL,
        forceRefresh: Bool = false,
        completion: @escaping (ExampleCharacterDetail) -> Void
    ) {
        scraper.fetch(
            from: url,
            forceRefresh: forceRefresh,
            completion: completion
        )
    }
}

// MARK: - Example 3: Tuple Return Type

class PageMetadataScraper {
    // WebScraper<(title: String, author: String, date: Date?)> - returns a tuple
    private let scraper: WebScraper<(title: String, author: String, date: Date?)>

    init() {
        self.scraper = WebScraper(
            category: "MetadataScraper",
            renderDelay: 2.0
        ) { doc, logger in
            let title = (try? doc.select("h1").text()) ?? "Untitled"
            let author =
                (try? doc.select("meta[name=author]").attr("content"))
                ?? "Unknown"

            let dateStr = try? doc.select("meta[name=date]").attr("content")
            let date = dateStr.flatMap { ISO8601DateFormatter().date(from: $0) }

            return (title: title, author: author, date: date)  // Returns tuple
        }
    }

    func fetchMetadata(
        from url: URL,
        completion:
            @escaping ((title: String, author: String, date: Date?)) -> Void
    ) {
        scraper.fetch(from: url, completion: completion)
    }
}

// MARK: - Example 4: Optional Return Type

class OptionalDataScraper {
    // WebScraper<String?> - returns optional
    private let scraper: WebScraper<String?>

    init() {
        self.scraper = WebScraper(
            category: "OptionalScraper",
            renderDelay: 2.0
        ) { doc, logger in
            // Returns nil if not found
            return try? doc.select("div.special-content").text()
        }
    }

    func fetchContent(from url: URL, completion: @escaping (String?) -> Void) {
        scraper.fetch(from: url, completion: completion)
    }
}
