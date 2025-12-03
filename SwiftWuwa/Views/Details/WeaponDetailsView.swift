//
//  WeaponDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/27.
//

import SDWebImageSwiftUI
import SwiftSoup
import SwiftUI

struct WeaponDetailsView: View {
    let weaponId: String

    @State private var viewModel = WeaponDetailsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let weaponDetails = viewModel.weaponDetails {
                    Section {
                        WebImage(url: weaponDetails.weaponImageURL)
                            .resizable()
                            .scaledToFit()
                            .listRowInsets(EdgeInsets())
                    }
                    Section("基础信息") {
                        if let baseInfo = weaponDetails.baseInfo {
                            ForEach(
                                Array(baseInfo).sorted(by: { $0.key < $1.key }),
                                id: \.0
                            ) { key, value in
                                LabeledContent {
                                    if value.starts(with: "http") {
                                        WebImage(url: URL(string: value))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 28)
                                    } else {
                                        Text(value)
                                    }
                                } label: {
                                    Text(key)
                                }
                            }
                        }
                    }
                    Section("武器描述") {
                        if let weaponDescription = weaponDetails
                            .weaponDescription
                        {
                            ForEach(
                                Array(weaponDescription).sorted(by: {
                                    $0.key < $1.key
                                }),
                                id: \.0
                            ) { key, value in
                                LabeledContent {
                                    Text(
                                        value.split(separator: " ").joined(
                                            separator: "\n"
                                        )
                                    )
                                } label: {
                                    if key != value {
                                        Text(key)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.weaponDetails == nil {
                    viewModel.loadWeaponDetails(itemId: weaponId)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

@Observable
final class WeaponDetailsViewModel {
    var weaponDetails: WeaponDetails?
    var isLoading = false

    func loadWeaponDetails(itemId: String) {
        isLoading = true
        WeaponDetailsScraper.shared.fetchWeaponDetails(itemId: itemId) {
            [weak self] weaponDetails in
            self?.weaponDetails = weaponDetails
            self?.isLoading = false
        }
    }
}

struct WeaponDetails {
    let id = UUID()
    let weaponImageURL: URL?
    let baseInfo: [String: String]?
    let weaponDescription: [String: String]?
}

class WeaponDetailsScraper {
    static let shared = WeaponDetailsScraper()

    private let scraper: WebScraper<WeaponDetails>

    private init() {
        self.scraper = WebScraper<WeaponDetails>(
            category: "WeaponDetailsScraper"
        ) { doc, logger in
            let imageString = try doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div.J-component-layout.component.component-size-small.component-float-none.basic-component > div > div.component-content.component-content-basic-component > div > div > table > tbody > tr:nth-child(1) > td > span > img"
            ).attr("src")

            let baseInfoRows = try doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div.J-component-layout.component.component-size-small.component-float-none.basic-component > div > div.component-content.component-content-basic-component > div > div > table > tbody > tr"
            )

            var baseInfo: [String: String] = [:]
            for row in baseInfoRows.dropFirst() {
                let cells = try row.select("td")
                let cellCount = cells.count

                if cellCount == 2 {
                    let key = try cells[0].text()
                    let value = try cells[1].text()
                    if value.isEmpty {
                        baseInfo[key] = try cells[1].select("img").attr("src")
                    } else {
                        baseInfo[key] = value
                    }
                }
            }

            // 武器描述
            let weaponDescriptionRows = try doc.select(
                "main > div.module-layout > div:nth-child(1) > div.component-container > div:nth-child(2) > div > div.component-content.component-content-basic-component > div > div > table > tbody > tr"
            )

            var weaponDescription: [String: String] = [:]
            for row in weaponDescriptionRows {
                if try row.select("td p").count == 3 {
                    let weaponDescriptionTitle = try row.select(
                        "td > p:nth-child(1)"
                    ).text()
                    let weaponDescriptionContent = try row.select(
                        "td > p:nth-child(3)"
                    ).text()
                    weaponDescription[weaponDescriptionTitle] =
                        weaponDescriptionContent
                } else if try row.select("td span").count == 1 {
                    let weaponDescriptionContent = try row.text()
                    let parts = weaponDescriptionContent.split(
                        separator: "："
                    )

                    if parts.count == 2 {
                        weaponDescription[String(parts[0])] = String(parts[1])
                    } else {
                        weaponDescription[weaponDescriptionContent] =
                            weaponDescriptionContent
                    }
                }
            }

            return WeaponDetails(
                weaponImageURL: URL(string: imageString),
                baseInfo: baseInfo,
                weaponDescription: weaponDescription
            )
        }
    }

    func fetchWeaponDetails(
        itemId: String,
        completion: @escaping (WeaponDetails) -> Void
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
    WeaponDetailsView(weaponId: "1438830164665520128")
}
