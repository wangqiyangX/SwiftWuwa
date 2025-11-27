//
//  CharacterGuideView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/26.
//

import Kingfisher
import SwiftSoup
import SwiftUI

struct CharacterGuideView: View {
    let characterId: String
    @State private var viewModel = CharacterGuideViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                if let characterGuide = viewModel.characterGuide {
                    if let profileImage = characterGuide.profileImage {
                        KFImage(profileImage)
                            .placeholder {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .listRowInsets(EdgeInsets())
                    }
                    Section("角色简评") {
                        Text(characterGuide.brief ?? "")
                    }
                    if let roleTags = characterGuide.roleTags {
                        Section {
                            ForEach(
                                Array(roleTags).sorted(by: { $0.key < $1.key }),
                                id: \.0
                            ) {
                                key,
                                value in
                                LabeledContent(key, value: value)
                            }
                        }
                    }
                    Section("战斗风格") {
                        if let fightingStyles = characterGuide.fightingStyles {
                            ForEach(fightingStyles, id: \.id) { style in
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
                                                        .frame(
                                                            maxWidth: .infinity
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Section("角色养成") {
                        if let skillPointRecommendation = characterGuide
                            .skillPointRecommendation
                        {
                            LabeledContent(
                                "加点推荐",
                                value: skillPointRecommendation
                            )
                        }
                    }
                    Section("角色机制") {
                        if let coreMechanism = characterGuide.coreMechanism {
                            LabeledContent("核心机制", value: coreMechanism)
                        }
                        if let outputProcess = characterGuide.outputProcess {
                            ForEach(
                                Array(outputProcess).sorted(by: {
                                    $0.key < $1.key
                                }),
                                id: \.key
                            ) {
                                process in
                                LabeledContent(
                                    process.key,
                                    value: process.value
                                )
                            }
                        }
                    }
                    Section("声骸推荐") {
                        if let voiceSetRecommendations = characterGuide
                            .voiceSetRecommendations
                        {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 8) {
                                    ForEach(voiceSetRecommendations, id: \.id) {
                                        voiceSet in
                                        if let icons = voiceSet.icons {
                                            ForEach(icons, id: \.self) {
                                                icon in
                                                VStack {
                                                    KFImage(icon)
                                                        .placeholder {
                                                            ProgressView()
                                                                .frame(
                                                                    maxWidth:
                                                                        .infinity
                                                                )
                                                        }
                                                        .resizable()
                                                        .aspectRatio(
                                                            contentMode: .fit
                                                        )
                                                        .frame(
                                                            width: 80,
                                                            height: 100
                                                        )
                                                    Text(
                                                        voiceSet.name ?? ""
                                                    )
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            ForEach(voiceSetRecommendations, id: \.id) {
                                voiceSet in
                                if let description = voiceSet.description,
                                    !description.isEmpty
                                {
                                    LabeledContent {
                                        Text(description)
                                    } label: {
                                        if let name = voiceSet.name {
                                            Text(name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.characterGuide?.name ?? "")
            .navigationSubtitle(viewModel.characterGuide?.description ?? "")
            .onAppear {
                viewModel.loadCharacterGuide(characterId: characterId)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        openURL(
                            URL(
                                string:
                                    "https://wiki.kurobbs.com/mc/item/\(characterId)"
                            )!
                        )
                    } label: {
                        Label("原网页", systemImage: "safari")
                    }
                }
            }
        }
    }
}

struct CharacterGuide {
    let id = UUID()
    let name: String?
    let description: String?
    let profileImage: URL?
    let attrImage: URL?
    let brief: String?
    let roleTags: [String: String]?
    let fightingStyles: [FightingStyle]?
    let skillPointRecommendation: String?
    let coreMechanism: String?
    let outputProcess: [String: String]?
    let voiceSetRecommendations: [VoiceSetRecommendation]?

    init(
        name: String? = nil,
        description: String? = nil,
        profileImage: URL? = nil,
        attrImage: URL? = nil,
        brief: String? = nil,
        roleTags: [String: String]? = nil,
        fightingStyles: [FightingStyle]? = nil,
        skillPointRecommendation: String? = nil,
        coreMechanism: String? = nil,
        outputProcess: [String: String]? = nil,
        voiceSetRecommendations: [VoiceSetRecommendation]? = nil
    ) {
        self.name = name
        self.description = description
        self.profileImage = profileImage
        self.attrImage = attrImage
        self.brief = brief
        self.roleTags = roleTags
        self.fightingStyles = fightingStyles
        self.skillPointRecommendation = skillPointRecommendation
        self.coreMechanism = coreMechanism
        self.outputProcess = outputProcess
        self.voiceSetRecommendations = voiceSetRecommendations
    }
}

struct VoiceSetRecommendation {
    let id = UUID()
    var name: String?
    var attrIcon: URL?
    var icons: [URL?]?
    var description: String?

    init(
        name: String? = nil,
        attrIcon: URL? = nil,
        icons: [URL?]? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.attrIcon = attrIcon
        self.icons = icons
        self.description = description
    }
}

@Observable
final class CharacterGuideViewModel {
    var characterGuide: CharacterGuide?
    var isLoading = false

    func loadCharacterGuide(characterId: String) {
        isLoading = true
        CharacterGuideScraper.shared.fetchCharacterGuide(itemId: characterId) {
            [weak self] guide in
            self?.characterGuide = guide
            self?.isLoading = false
        }
    }
}

class CharacterGuideScraper {
    static let shared = CharacterGuideScraper()

    private let scraper: WebScraper<CharacterGuide>

    init() {
        self.scraper = WebScraper(category: "CharacterGuideScraper") {
            doc,
            logger in
            if let mainElement = try? doc.select("main") {
                let name = try mainElement.select("div.name.text-ellipsis")
                    .text()
                let description = try mainElement.select("div.description")
                    .text()
                let image = try mainElement.select("div.role-images img").attr(
                    "src"
                )
                let attrImage = try mainElement.select(
                    "div.role-profile > div.main-info > div.left-attribute img"
                ).attr("src")
                let brief = try mainElement.select(" div.role-description")
                    .text()
                var roleTags: [String: String] = [:]

                // 角色标签
                let roleTagElements = try mainElement.select(
                    "div.role-profile > div.role-tags > div"
                )

                for tagElement in roleTagElements {
                    if let tagText = try? tagElement.text() {
                        let tagKey = tagText.split(separator: "：")[0]
                        let tagValue = tagText.split(separator: "：")[1]

                        roleTags[String(tagKey)] = String(tagValue)
                    }
                }

                // 战斗风格
                let fightingStyleTable = try mainElement.select(
                    "div.module-layout > div:nth-child(1) > div.component-container > div.J-component-layout.component.component-size-large.component-float-none.basic-component > div > div.component-content.component-content-basic-component > div > div > table > tbody"
                )

                let fightingStyleRows = try fightingStyleTable.select("tr")

                var fightingStyles: [FightingStyle] = []

                for row in fightingStyleRows {
                    let cells = try row.select("td")
                    let fightingStyleIcon = try cells[0].select("img").attr(
                        "src"
                    )
                    let fightingStyleName = try cells[1].select(
                        "p:nth-child(1)"
                    ).text()
                    let fightingStyleDescription = try cells[1].select(
                        "p:nth-child(2)"
                    ).text()

                    fightingStyles.append(
                        FightingStyle(
                            icon: URL(string: fightingStyleIcon),
                            name: fightingStyleName,
                            description: fightingStyleDescription
                        )
                    )
                }

                // 角色养成
                // 技能加点推荐
                let skillPointRecommendation = try mainElement.select(
                    "div.module-layout > div:nth-child(2) > div.component-container > div > div > div.component-content.component-content-basic-component > div > div > table:nth-child(1) > tbody > tr > td:nth-child(2)"
                ).text()

                // let breakThroughMaterials = try mainElement.select(
                //     "div.module-layout > div:nth-child(2) > div.component-container > div > div > div.component-content.component-content-basic-component > div > div > table:nth-child(2) > tbody"
                // ).text()

                // print(breakThroughMaterials)

                // 核心机制
                let coreMechanism = try mainElement.select(
                    "div.module-layout > div:nth-child(3) > div.component-container > div > div > div.component-content.component-content-tabs-component > div > div:nth-child(1) > table > tbody > tr > td:nth-child(2)"
                ).text()

                // 输出流程
                let outpubProcessParagraphs = try mainElement.select(
                    "div.module-layout > div:nth-child(3) > div.component-container > div > div > div.component-content.component-content-tabs-component > div > div:nth-child(2) > table > tbody > tr > td:nth-child(2) > p"
                )

                var outputProcess: [String: String] = [:]

                for paragraph in outpubProcessParagraphs {
                    let text = try paragraph.text()
                    let parts = text.split(separator: "：")
                    if parts.count == 2 {
                        outputProcess[String(parts[0])] = String(parts[1])
                    } else {
                        outputProcess["基础流程"] = String(parts[0])
                    }
                }

                // 声骸套装推荐
                let voiceSetRecommendationRows = try mainElement.select(
                    "div.module-layout > div:nth-child(4) > div.component-container > div > div > div.component-content.component-content-tabs-component > div > div:nth-child(1) > table > tbody > tr"
                )

                var voiceSetRecommendations: [VoiceSetRecommendation] = []

                for row in voiceSetRecommendationRows {
                    let cells = try row.select("td")

                    let voiceSetRecommendationAttrIcon = try cells[0]
                        .select("img").attr(
                            "src"
                        )

                    let voiceSetRecommendationName = try cells[0].text()

                    let voiceSetRecommendationIcons = try cells[1].select(
                        "img"
                    ).map(
                        { try $0.attr("src") }
                    )

                    let voiceSetRecommendationDescription = try cells[1]
                        .text()

                    voiceSetRecommendations.append(
                        VoiceSetRecommendation(
                            name: voiceSetRecommendationName,
                            attrIcon: URL(
                                string: voiceSetRecommendationAttrIcon
                            ),
                            icons: voiceSetRecommendationIcons.map(
                                { URL(string: $0) }
                            ),
                            description: voiceSetRecommendationDescription
                        )
                    )
                }

                return CharacterGuide(
                    name: name,
                    description: description,
                    profileImage: URL(string: image),
                    attrImage: URL(string: attrImage),
                    brief: brief,
                    roleTags: roleTags,
                    fightingStyles: fightingStyles,
                    skillPointRecommendation: skillPointRecommendation,
                    coreMechanism: coreMechanism,
                    outputProcess: outputProcess,
                    voiceSetRecommendations: voiceSetRecommendations
                )
            }

            return CharacterGuide()
        }
    }

    func fetchCharacterGuide(
        itemId: String,
        completion: @escaping (CharacterGuide) -> Void
    ) {
        scraper.fetch(
            from: URL(
                string:
                    "https://wiki.kurobbs.com/mc/item/\(itemId)"
            )!,
            completion: completion
        )
    }
}

#Preview {
    CharacterGuideView(characterId: "1437636572639440896")
}
