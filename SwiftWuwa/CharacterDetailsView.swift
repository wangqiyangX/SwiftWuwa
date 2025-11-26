//
//  CharacterDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/24.
//

import Foundation
import Kingfisher
import OSLog
import SwiftSoup
import SwiftUI

struct CharacterDetail {
    let info: BaseInfo
    let additionalInfo: AdditionalInfo
    let characterStatistics: CharacterStatistics
    let fightingStyles: [FightingStyle]
    let skillIntroductions: SkillIntroductions
    let resonanceChain: [ResonanceChainItem]
    let breakthroughMaterials: BreakthroughMaterials
}

struct BaseInfo {
    let name: String?
    let description: String?
    let roleDescriptionTitle: String?
    let roleDescription: String?
    let roleTags: [String]?
    let roleImages: [URL]?
}

struct AdditionalInfo {
    let identity: String?
    let belong: String?
    let specialCuisine: String?
    let chineseCV: String?
    let japaneseCV: String?
    let englishCV: String?
    let koreanCV: String?
    let appearVersion: String?
}

struct CharacterStatistics {
    // Dictionary keyed by level (1, 10, 20, 30, 40, 50, 60, 70, 80, 90)
    var statisticsByLevel: [Int: [String: String]] = [:]

    // Convenience accessors for each level
    var level1: [String: String] { statisticsByLevel[1] ?? [:] }
    var level20: [String: String] { statisticsByLevel[20] ?? [:] }
    var level40: [String: String] { statisticsByLevel[40] ?? [:] }
    var level50: [String: String] { statisticsByLevel[50] ?? [:] }
    var level60: [String: String] { statisticsByLevel[60] ?? [:] }
    var level70: [String: String] { statisticsByLevel[70] ?? [:] }
    var level80: [String: String] { statisticsByLevel[80] ?? [:] }
    var level90: [String: String] { statisticsByLevel[90] ?? [:] }
}

struct FightingStyle {
    let id = UUID()
    let icon: URL?
    let name: String?
    let description: String?
}

struct SkillIntroductions {
    let normalAttack: NormalAttack
    let resonanceSkills: ResonanceSkills
    let resonanceLoop: ResonanceLoop
    let resonanceLiberation: ResonanceLiberation
    let variationSkill: VariationSkill
    let sustainabilitySkill: SustainabilitySkill
}

struct NormalAttack {
    let name: String?
    let icon: URL?
    let items: [String: String]
}

struct ResonanceLoop {
    let name: String?
    let icon: URL?
    let items: [String: String]
}

struct ResonanceSkills {
    let name: String?
    let icon: URL?
    let items: [String: String]
}

struct ResonanceLiberation {
    let name: String?
    let icon: URL?
    let description: String?
    let items: [String: String]
}

struct VariationSkill {
    let name: String?
    let icon: URL?
    let description: String?
}

struct SustainabilitySkill {
    let name: String?
    let icon: URL?
    let description: String?
}

struct ResonanceChainItem {
    let id = UUID()
    let name: String?
    let icon: URL?
    let description: String?
}

struct BreakthroughMaterials {
    let firstLevelBreakthrough: BreakthroughInfo
    let secondLevelBreakthrough: BreakthroughInfo
    let thirdLevelBreakthrough: BreakthroughInfo
    let fourthLevelBreakthrough: BreakthroughInfo
    let fifthLevelBreakthrough: BreakthroughInfo
    let sixthLevelBreakthrough: BreakthroughInfo
}

struct BreakthroughInfo {
    let requiredLevel: String?
    let levelCap: String?
    let materials: [BreakthroughMaterial]
}

struct BreakthroughMaterial {
    let id = UUID()
    let name: String?
    let icon: URL?
    let count: String?
}

enum BreakthroughLevel: Int, CaseIterable {
    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    case fifth = 5
    case sixth = 6

    var label: String {
        switch self {
        case .first:
            "一阶"
        case .second:
            "二阶"
        case .third:
            "三阶"
        case .fourth:
            "四阶"
        case .fifth:
            "五阶"
        case .sixth:
            "六阶"
        }
    }

    var id: Self { self }
}

/// EncyclopediaScraper for fetching character previews from the wiki catalogue
class CharacterDetailsScraper {
    static let shared = CharacterDetailsScraper()

    private let scraper: WebScraper<CharacterDetail>

    private init() {
        // Define the parsing strategy for character previews
        self.scraper = WebScraper(
            category: "CharacterDetailsScraper"
        ) { doc, logger in

            let name = try? doc.select("div.main-info div.name").text()
            let description = try? doc.select("div.main-info div.description")
                .text()
            let roleDescriptionTitle = try? doc.select(
                "div.role-profile div.role-description-title"
            ).text()
            let roleDescription = try? doc.select(
                "div.role-profile div.role-description"
            ).text()

            // 获取标签信息
            var roleTagsArray: [String] = []
            if let roleTags = try? doc.select(
                "div.role-profile div.role-tags div"
            ) {
                for tag in roleTags {
                    if let tagText = try? tag.text(), !tagText.isEmpty {
                        roleTagsArray.append(tagText)
                    }
                }
            }

            var roleImagesArray: [URL] = []
            if let roleImages = try? doc.select("div.role-images img") {
                for image in roleImages {
                    if let imageUrl = try? image.attr("src"), !imageUrl.isEmpty,
                        let url = URL(string: imageUrl)
                    {
                        roleImagesArray.append(url)
                    }
                }
            }

            let additionalInfoTableRows = try? doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div.J-component-layout.component.component-size-small.component-float-none.basic-component > div > div.component-content.component-content-basic-component > div > div > table > tbody > tr"
            )

            var additionalInfo: [String: String] = [:]

            if let rows = additionalInfoTableRows {
                for row in rows {
                    let cells = try? row.select("td")
                    if let infoKey = try cells?[0].text(),
                        let infoValue = try cells?[1].text()
                    {
                        additionalInfo[infoKey] = infoValue
                    }
                }
            }

            let statisticsTables = try doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div.J-component-layout.component.component-size-medium.component-float-none.tabs-component > div > div.component-content.component-content-tabs-component > div > div > table > tbody"
            )

            // Parse statistics tables - each table corresponds to a level
            // Levels: 1, 10, 20, 30, 40, 50, 60, 70, 80, 90
            var statistics = CharacterStatistics()
            let levels = [1, 20, 40, 50, 60, 70, 80, 90]

            for (index, statisticsTable) in statisticsTables.enumerated() {
                guard index < levels.count else { break }
                let level = levels[index]
                var levelStats: [String: String] = [:]

                let rows = try statisticsTable.select("tr")
                for row in rows {
                    let tds = try row.select("td")
                    // Each row has 4 cells: key1, value1, key2, value2
                    if tds.count == 4 {
                        if let key1 = try? tds[0].text(), !key1.isEmpty,
                            let value1 = try? tds[1].text(),
                            let key2 = try? tds[2].text(), !key2.isEmpty,
                            let value2 = try? tds[3].text()
                        {
                            levelStats[key1] = value1
                            levelStats[key2] = value2
                        }
                    } else {
                        if let key1 = try? tds[0].text(), !key1.isEmpty,
                            let value1 = try? tds[1].text(),
                            let value2 = try? tds[2].text(),
                            let key2 = try? tds[3].text(), !key2.isEmpty,
                            let value3 = try? tds[4].text()
                        {
                            levelStats[key1] = "\(value1)-\(value2)"
                            levelStats[key2] = value3
                        }
                    }
                }

                statistics.statisticsByLevel[level] = levelStats
            }

            let fightingStyleTable = try doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div:nth-child(4) > div > div.component-content.component-content-basic-component > div > div > table > tbody > tr"
            )

            var fightingStyles: [FightingStyle] = []
            for row in fightingStyleTable {
                let cells = try row.select("td")
                let icon = try cells[0].select("img").attr("src")
                let name = try cells[1].select("p:nth-child(1)").text()
                let description = try cells[1].select("p:nth-child(2)").text()
                fightingStyles.append(
                    FightingStyle(
                        icon: URL(string: icon)!,
                        name: name,
                        description: description
                    )
                )
            }

            let skillIntroductions = try doc.select(
                "main > div.module-layout > div:nth-child(2) > div.component-container > div:nth-child(1) > div > div.component-content.component-content-tabs-component > div > div.component-content-text"
            )

            let normalAttackParagraphs = try skillIntroductions[0].select("> p")

            let normalAttackName = try? normalAttackParagraphs[0].select(
                "strong"
            ).text()
            let normalAttackIcon = try? normalAttackParagraphs[0].select("img")
                .attr("src")

            // 循环提取普通攻击项(跳过第一个段落)
            var normalAttackItems: [String: String] = [:]

            for paragraph in normalAttackParagraphs.dropFirst() {
                let normalAttackItem = try paragraph.text()
                let parts = normalAttackItem.split(separator: " ")
                let itemName = String(parts[0])
                let itemDescription = parts[1...].joined(separator: "\n")

                normalAttackItems[itemName] = itemDescription
            }

            let resonanceSkillsParagraphs = try skillIntroductions[1].select(
                " > p"
            )
            let resonanceSkillsName = try? resonanceSkillsParagraphs[0].select(
                "> span > strong > span > strong > span"
            ).text()
            let resonanceSkillsIcon = try? resonanceSkillsParagraphs[0].select(
                "img"
            ).attr("src")

            // 循环提取共鸣技能项(跳过第一个段落)
            var resonanceSkillsItems: [String: String] = [:]

            for paragraph in resonanceSkillsParagraphs.dropFirst() {
                let resonanceSkillsItem = try paragraph.text()
                let parts = resonanceSkillsItem.split(separator: " ")
                let itemName = String(parts[0])
                let itemDescription = parts[1...].joined(separator: "\n")

                resonanceSkillsItems[itemName] = itemDescription
            }

            let resonanceLoopParagraphs = try skillIntroductions[2].select(
                " > p"
            )
            let resonanceLoopName = try? resonanceLoopParagraphs[0].select(
                "> span > strong"
            ).text()
            let resonanceLoopIcon = try? resonanceLoopParagraphs[0].select(
                "img"
            ).attr("src")

            // 循环提取共鸣回路项(跳过第一个段落)
            var resonanceLoopItems: [String: String] = [:]

            for paragraph in resonanceLoopParagraphs.dropFirst() {
                let resonanceLoopItem = try paragraph.text()
                let parts = resonanceLoopItem.split(separator: " ")
                let itemName = String(parts[0])
                let itemDescription = parts[1...].joined(separator: "\n")

                resonanceLoopItems[itemName] = itemDescription
            }

            let resonanceLiberationParagraphs = try skillIntroductions[3]
                .select(
                    " > p"
                )

            let resonanceLiberationName = try? resonanceLiberationParagraphs[0]
                .select(
                    "> span > strong"
                ).text()
            let resonanceLiberationIcon = try? resonanceLiberationParagraphs[0]
                .select(
                    "img"
                ).attr("src")
            let resonanceLiberationDescription =
                try? resonanceLiberationParagraphs[1]
                .text().split(separator: " ").joined(separator: "\n")

            // 循环提取共鸣解放项(跳过第一个段落)
            var resonanceLiberationItems: [String: String] = [:]

            for paragraph in resonanceLiberationParagraphs.dropFirst()
                .dropFirst()
            {
                let resonanceLiberationItem = try paragraph.text()
                let parts = resonanceLiberationItem.split(separator: " ")
                let itemName = String(parts[0])
                let itemDescription = parts[1...].joined(separator: "\n")

                resonanceLiberationItems[itemName] = itemDescription
            }

            // 变奏技能
            let variationSkillParagraphs = try skillIntroductions[4].select(
                " > p"
            )

            let variationSkillName = try? variationSkillParagraphs[0].select(
                "> span > strong > span > strong"
            ).text()
            let variationSkillIcon = try? variationSkillParagraphs[0].select(
                "img"
            ).attr("src")
            let variationSkillDescription = try? variationSkillParagraphs[1]
                .text().split(separator: " ").joined(separator: "\n")

            // 延奏技能
            let sustainabilitySkillParagraphs = try skillIntroductions[5]
                .select(
                    " > p"
                )

            let sustainabilitySkillName = try? sustainabilitySkillParagraphs[0]
                .select(
                    "> span > span > strong"
                ).text()
            let sustainabilitySkillIcon = try? sustainabilitySkillParagraphs[0]
                .select(
                    "img"
                ).attr("src")
            let sustainabilitySkillDescription =
                try? sustainabilitySkillParagraphs[1]
                .text().split(separator: " ").joined(separator: "\n")

            // 共鸣链
            let resonanceChainTable = try doc.select(
                "main > div.module-layout > div:nth-child(2) > div.component-container > div.J-component-layout.component.component-size-large.component-float-none.basic-component > div > div.component-content.component-content-basic-component > div > div > table > tbody"
            )

            let resonanceChainTableRows = try resonanceChainTable.select("tr")

            var resonanceChainItems: [ResonanceChainItem] = []

            for row in resonanceChainTableRows.dropFirst() {
                let cells = try row.select("td")
                let name = try cells[0].text()
                let icon = try cells[0].select("img").attr("src")
                let description = try cells[1].text().split(separator: " ")
                    .joined(separator: "\n")

                resonanceChainItems.append(
                    ResonanceChainItem(
                        name: name,
                        icon: URL(string: icon),
                        description: description
                    )
                )
            }

            // 突破材料
            let breakthroughMaterials = try doc.select(
                "main > div.module-layout > div:nth-child(2) > div.component-container > div:nth-child(3) > div > div.component-content.component-content-tabs-component > div.component-content-inner > div"
            )

            // Helper function to parse breakthrough info
            func parseBreakthroughInfo(at index: Int) throws -> BreakthroughInfo
            {
                let tables = try breakthroughMaterials[index].select("table")
                let rowsOfTable0 = try tables[0].select("tr")

                // 所需等级
                let requiredLevel = try rowsOfTable0[0].select("td")[1].text()
                // 等级上限
                let levelCap = try rowsOfTable0[1].select("td")[1].text()

                let rowsOfTable1 = try tables[1].select("tr")
                var materials: [BreakthroughMaterial] = []

                for row in rowsOfTable1 {
                    let cells = try row.select("td")
                    for cell in cells {
                        let name = try cell.select("p > a").text()
                        let icon = try cell.select("p img").attr("src")
                        let count = try cell.select("p").text().split(
                            separator: "x"
                        )[1]

                        materials.append(
                            BreakthroughMaterial(
                                name: name,
                                icon: URL(string: icon),
                                count: String(count)
                            )
                        )
                    }
                }

                return BreakthroughInfo(
                    requiredLevel: requiredLevel,
                    levelCap: levelCap,
                    materials: materials
                )
            }

            // Parse all six breakthrough stages
            let firstLevelBreakthrough = try parseBreakthroughInfo(at: 0)
            let secondLevelBreakthrough = try parseBreakthroughInfo(at: 1)
            let thirdLevelBreakthrough = try parseBreakthroughInfo(at: 2)
            let fourthLevelBreakthrough = try parseBreakthroughInfo(at: 3)
            let fifthLevelBreakthrough = try parseBreakthroughInfo(at: 4)
            let sixthLevelBreakthrough = try parseBreakthroughInfo(at: 5)

            return CharacterDetail(
                info: .init(
                    name: name,
                    description: description,
                    roleDescriptionTitle: roleDescriptionTitle,
                    roleDescription: roleDescription,
                    roleTags: roleTagsArray,
                    roleImages: roleImagesArray,
                ),
                additionalInfo: AdditionalInfo(
                    identity: additionalInfo["身份"],
                    belong: additionalInfo["所属"],
                    specialCuisine: additionalInfo["特殊料理"],
                    chineseCV: additionalInfo["中文CV"],
                    japaneseCV: additionalInfo["日文CV"],
                    englishCV: additionalInfo["英文CV"],
                    koreanCV: additionalInfo["韩文CV"],
                    appearVersion: additionalInfo["实装版本"]
                ),
                characterStatistics: statistics,
                fightingStyles: fightingStyles,
                skillIntroductions: SkillIntroductions(
                    normalAttack: NormalAttack(
                        name: normalAttackName,
                        icon: URL(string: normalAttackIcon ?? "")!,
                        items: normalAttackItems
                    ),
                    resonanceSkills: ResonanceSkills(
                        name: resonanceSkillsName,
                        icon: URL(string: resonanceSkillsIcon ?? "")!,
                        items: resonanceSkillsItems
                    ),
                    resonanceLoop: ResonanceLoop(
                        name: resonanceLoopName,
                        icon: URL(string: resonanceLoopIcon ?? "")!,
                        items: resonanceLoopItems
                    ),
                    resonanceLiberation: ResonanceLiberation(
                        name: resonanceLiberationName,
                        icon: URL(string: resonanceLiberationIcon ?? "")!,
                        description: resonanceLiberationDescription,
                        items: resonanceLiberationItems
                    ),
                    variationSkill: VariationSkill(
                        name: variationSkillName,
                        icon: URL(string: variationSkillIcon ?? "")!,
                        description: variationSkillDescription
                    ),
                    sustainabilitySkill: SustainabilitySkill(
                        name: sustainabilitySkillName,
                        icon: URL(string: sustainabilitySkillIcon ?? "")!,
                        description: sustainabilitySkillDescription
                    )
                ),
                resonanceChain: resonanceChainItems,
                breakthroughMaterials: BreakthroughMaterials(
                    firstLevelBreakthrough: firstLevelBreakthrough,
                    secondLevelBreakthrough: secondLevelBreakthrough,
                    thirdLevelBreakthrough: thirdLevelBreakthrough,
                    fourthLevelBreakthrough: fourthLevelBreakthrough,
                    fifthLevelBreakthrough: fifthLevelBreakthrough,
                    sixthLevelBreakthrough: sixthLevelBreakthrough
                )
            )
        }
    }

    /// Fetch entries from the wiki catalogue for a specific category
    /// - Parameters:
    ///   - category: The catalogue category to fetch
    ///   - forceRefresh: If true, bypass cache and fetch fresh data. Default is false.
    ///   - completion: Completion handler with parsed results
    func fetchDetails(
        itemId: String,
        forceRefresh: Bool = false,
        completion: @escaping (CharacterDetail) -> Void
    ) {
        scraper.fetch(
            from: URL(
                string: "https://wiki.kurobbs.com/mc/item/\(itemId)"
            )!,
            forceRefresh: forceRefresh,
            completion: completion
        )
    }

    /// Clear cached character data
    func clearCache() {
        scraper.clearCache()
    }
}

@Observable
final class CharacterDetailsViewModel {
    var characterDatail: CharacterDetail?
    var isLoading = false

    func loadCharacterDetails(characterId: String) {
        isLoading = true
        CharacterDetailsScraper.shared.fetchDetails(itemId: characterId) {
            [weak self] details in
            self?.characterDatail = details
            self?.isLoading = false
        }
    }
}

enum CharacterLevel: CaseIterable {
    case level1
    case level20
    case level30
    case level40
    case level50
    case level60
    case level70
    case level80
    case level90

    var level: Int {
        switch self {
        case .level1: return 1
        case .level20: return 20
        case .level30: return 30
        case .level40: return 40
        case .level50: return 50
        case .level60: return 60
        case .level70: return 70
        case .level80: return 80
        case .level90: return 90
        }
    }
}

enum SkillType: CaseIterable {
    case normalAttack
    case resonanceSkills
    case resonanceLoop
    case resonanceLiberation
    case variationSkill
    case sustainabilitySkill

    var name: String {
        switch self {
        case .normalAttack: "常态攻击"
        case .resonanceSkills: "共鸣技能"
        case .resonanceLoop: "共鸣回路"
        case .resonanceLiberation: "共鸣解放"
        case .variationSkill: "变奏技能"
        case .sustainabilitySkill: "延奏技能"
        }
    }
}

struct CharacterDetailsView: View {
    let characterId: String

    @State private var viewModel = CharacterDetailsViewModel()
    @State private var selectedLevel = 1
    @State private var selectedSkillType: SkillType = .normalAttack
    @State private var selectedBreakthroughLevel: BreakthroughLevel = .first

    var body: some View {
        NavigationStack {
            List {
                if let details = viewModel.characterDatail {
                    if let roleImages = details.info.roleImages {
                        TabView {
                            ForEach(roleImages, id: \.self) { image in
                                KFImage(image)
                                    .placeholder {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                        #if os(iOS)
                            .tabViewStyle(.page)
                        #endif
                        .frame(minHeight: 320)
                        .listRowInsets(EdgeInsets())
                    }

                    Section("基本信息") {
                        if let roleDescriptionTitle = details.info
                            .roleDescriptionTitle
                        {
                            LabeledContent(
                                roleDescriptionTitle.split(separator: "：")[0],
                                value: roleDescriptionTitle.split(
                                    separator: "："
                                )[1]
                            )
                        }
                        if let roleDescription = details.info.roleDescription {
                            Text(roleDescription)
                        }

                        if let roleTags = details.info.roleTags {
                            ForEach(roleTags, id: \.self) { tag in
                                LabeledContent(
                                    tag.split(separator: "：")[0],
                                    value: tag.split(separator: "：")[1]
                                )
                            }
                        }
                    }

                    Section("其他消息") {
                        if let identity = details.additionalInfo.identity {
                            LabeledContent("身份", value: identity)
                        }

                        if let belong = details.additionalInfo.belong {
                            LabeledContent("所属", value: belong)
                        }

                        if let specialCuisine = details.additionalInfo
                            .specialCuisine
                        {
                            LabeledContent("特殊料理", value: specialCuisine)
                        }

                        if let chineseCV = details.additionalInfo.chineseCV {
                            LabeledContent("中文CV", value: chineseCV)
                        }

                        if let japaneseCV = details.additionalInfo.japaneseCV {
                            LabeledContent("日文CV", value: japaneseCV)
                        }

                        if let englishCV = details.additionalInfo.englishCV {
                            LabeledContent("英文CV", value: englishCV)
                        }

                        if let koreanCV = details.additionalInfo.koreanCV {
                            LabeledContent("韩文CV", value: koreanCV)
                        }

                        if let appearVersion = details.additionalInfo
                            .appearVersion
                        {
                            LabeledContent("实装版本", value: appearVersion)
                        }
                    }

                    Section("角色统计") {
                        Picker("等级", selection: $selectedLevel) {
                            ForEach(
                                [1, 20, 40, 50, 60, 70, 80, 90],
                                id: \.self
                            ) { level in
                                Text("\(level)").tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let stats = details.characterStatistics
                            .statisticsByLevel[selectedLevel]
                        {
                            ForEach(stats.keys.sorted(), id: \.self) { key in
                                if let value = stats[key] {
                                    LabeledContent(key, value: value)
                                }
                            }
                        } else {
                            Text("暂无数据")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("战斗风格") {
                        ForEach(details.fightingStyles, id: \.id) { style in
                            LabeledContent {
                                if let description = style.description {
                                    Text(description)
                                }
                            } label: {
                                Label {
                                    if let name = style.name {
                                        Text(name)
                                    }
                                } icon: {
                                    if let iconURL = style.icon {
                                        KFImage(iconURL)
                                            .placeholder {
                                                ProgressView()
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        switch selectedSkillType {
                        case .normalAttack:
                            Label {
                                Text(
                                    details.skillIntroductions.normalAttack.name
                                        ?? ""
                                )
                            } icon: {
                                KFImage(
                                    details.skillIntroductions.normalAttack.icon
                                )
                                .placeholder {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            }
                            ForEach(
                                details.skillIntroductions.normalAttack.items
                                    .keys
                                    .sorted(),
                                id: \.self
                            ) { key in
                                if let value = details.skillIntroductions
                                    .normalAttack.items[key]
                                {
                                    //                                    LabeledContent(key, value: value)
                                    VStack(alignment: .leading) {
                                        Text(key)
                                        Text(value)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        case .resonanceSkills:
                            Label {
                                Text(
                                    details.skillIntroductions.resonanceSkills
                                        .name
                                        ?? ""
                                )
                            } icon: {
                                KFImage(
                                    details.skillIntroductions.resonanceSkills
                                        .icon
                                )
                                .placeholder {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            }
                            ForEach(
                                details.skillIntroductions.resonanceSkills.items
                                    .keys
                                    .sorted(),
                                id: \.self
                            ) { key in
                                if let value = details.skillIntroductions
                                    .resonanceSkills.items[key]
                                {
                                    //                                    LabeledContent(key, value: value)
                                    VStack(alignment: .leading) {
                                        Text(key)
                                        Text(value)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        case .resonanceLoop:
                            Label {
                                Text(
                                    details.skillIntroductions.resonanceLoop
                                        .name ?? ""
                                )
                            } icon: {
                                KFImage(
                                    details.skillIntroductions
                                        .resonanceLoop
                                        .icon
                                )
                                .placeholder {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            }
                            ForEach(
                                details.skillIntroductions.resonanceLoop
                                    .items.keys.sorted(),
                                id: \.self
                            ) { key in
                                if let value = details.skillIntroductions
                                    .resonanceLoop.items[
                                        key
                                    ]
                                {
                                    //                                    LabeledContent(key, value: value)
                                    VStack(alignment: .leading) {
                                        Text(key)
                                        Text(value)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        case .resonanceLiberation:
                            LabeledContent {
                                Text(
                                    details.skillIntroductions
                                        .resonanceLiberation
                                        .description
                                        ?? ""
                                )
                            } label: {
                                Label {
                                    Text(
                                        details.skillIntroductions
                                            .resonanceLiberation
                                            .name
                                            ?? ""
                                    )
                                } icon: {
                                    KFImage(
                                        details.skillIntroductions
                                            .resonanceLiberation
                                            .icon
                                    )
                                    .placeholder {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                }
                            }
                            ForEach(
                                details.skillIntroductions.resonanceLiberation
                                    .items
                                    .keys
                                    .sorted(),
                                id: \.self
                            ) { key in
                                if let value = details.skillIntroductions
                                    .resonanceLiberation.items[key]
                                {
                                    //                                    LabeledContent(key, value: value)
                                    VStack(alignment: .leading) {
                                        Text(key)
                                        Text(value)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        case .variationSkill:
                            LabeledContent {
                                Text(
                                    details.skillIntroductions.variationSkill
                                        .description
                                        ?? ""
                                )
                            } label: {
                                Label {
                                    Text(
                                        details.skillIntroductions
                                            .variationSkill
                                            .name
                                            ?? ""
                                    )
                                } icon: {
                                    KFImage(
                                        details.skillIntroductions
                                            .variationSkill
                                            .icon
                                    )
                                    .placeholder {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                }
                            }
                        case .sustainabilitySkill:
                            LabeledContent {
                                Text(
                                    details.skillIntroductions
                                        .sustainabilitySkill
                                        .description
                                        ?? ""
                                )
                            } label: {
                                Label {
                                    Text(
                                        details.skillIntroductions
                                            .sustainabilitySkill
                                            .name
                                            ?? ""
                                    )
                                } icon: {
                                    KFImage(
                                        details.skillIntroductions
                                            .sustainabilitySkill
                                            .icon
                                    )
                                    .placeholder {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("技能介绍")
                            Spacer()
                            Picker("选择技能", selection: $selectedSkillType) {
                                ForEach(SkillType.allCases, id: \.self) {
                                    skillType in
                                    Text(skillType.name)
                                }
                            }
                        }
                    }

                    Section("共鸣链") {
                        ForEach(details.resonanceChain, id: \.id) { item in
                            //                            LabeledContent {
                            //                                Text(item.description ?? "")
                            //                            } label: {
                            //                                Label {
                            //                                    Text(item.name ?? "")
                            //                                } icon: {
                            //                                    KFImage(item.icon)
                            //                                        .placeholder {
                            //                                            ProgressView()
                            //                                                .frame(maxWidth: .infinity)
                            //                                        }
                            //                                        .resizable()
                            //                                        .aspectRatio(contentMode: .fit)
                            //                                        .frame(width: 20, height: 20)
                            //                                }
                            //                            }
                            VStack(alignment: .leading) {
                                Label {
                                    Text(item.name ?? "")
                                } icon: {
                                    KFImage(item.icon)
                                        .placeholder {
                                            ProgressView()
                                                .frame(maxWidth: .infinity)
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                                Text(item.description ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("突破材料") {
                        Picker("突破等级", selection: $selectedBreakthroughLevel) {
                            ForEach(BreakthroughLevel.allCases, id: \.self) {
                                level in
                                Text(level.label)
                                    .tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch selectedBreakthroughLevel {
                        case .first:
                            if let requiredLevel = details.breakthroughMaterials
                                .firstLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .firstLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }
                            ForEach(
                                details.breakthroughMaterials
                                    .firstLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        case .second:
                            if let requiredLevel = details.breakthroughMaterials
                                .secondLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .secondLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }
                            ForEach(
                                details.breakthroughMaterials
                                    .secondLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        case .third:
                            if let requiredLevel = details.breakthroughMaterials
                                .thirdLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .thirdLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }
                            ForEach(
                                details.breakthroughMaterials
                                    .thirdLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        case .fourth:
                            if let requiredLevel = details.breakthroughMaterials
                                .fourthLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .fourthLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }

                            ForEach(
                                details.breakthroughMaterials
                                    .fourthLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        case .fifth:
                            if let requiredLevel = details.breakthroughMaterials
                                .fifthLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .fifthLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }

                            ForEach(
                                details.breakthroughMaterials
                                    .fifthLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        case .sixth:
                            if let requiredLevel = details.breakthroughMaterials
                                .sixthLevelBreakthrough.requiredLevel
                            {
                                LabeledContent(
                                    "所需等级",
                                    value: requiredLevel
                                )
                            }

                            if let levelCap = details.breakthroughMaterials
                                .sixthLevelBreakthrough.levelCap
                            {
                                LabeledContent(
                                    "等级上限",
                                    value: levelCap
                                )
                            }

                            ForEach(
                                details.breakthroughMaterials
                                    .sixthLevelBreakthrough.materials,
                                id: \.id
                            ) { material in
                                LabeledContent {
                                    if let count = material.count {
                                        Text(count)
                                    }
                                } label: {
                                    Label {
                                        if let name = material.name {
                                            Text(name)
                                        }
                                    } icon: {
                                        if let icon = material.icon {
                                            KFImage(icon)
                                                .placeholder {
                                                    ProgressView()
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.characterDatail?.info.name ?? "")
            .navigationSubtitle(
                viewModel.characterDatail?.info.description ?? ""
            )
            .onAppear {
                viewModel.loadCharacterDetails(characterId: characterId)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                }
            }
            .listStyle(.sidebar)
        }
    }
}

#Preview {
    CharacterDetailsView(characterId: "1429457793942482944")
}
