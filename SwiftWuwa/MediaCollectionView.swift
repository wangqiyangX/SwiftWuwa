//
//  MediaCollectionView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/26.
//

import Kingfisher
import SwiftSoup
import SwiftUI

enum MediaType: String, CaseIterable, Identifiable {
    case fanArt = "同人绘画"
    case emoticon = "表情包"
    case wallpaper = "壁纸合集"
    case versionPV = "版本PV"
    case characterPV = "共鸣者PV"
    case characterCombatDemo = "共鸣者战斗演示"
    case storyAnimation = "剧情动画"
    case radioEP = "先约电台EP"
    case radioOST = "先约电台OST"
    case otherMedia = "其他影音"

    var id: String { rawValue }

    var url: URL {
        let urlString: String
        switch self {
        case .fanArt:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1343"
        case .emoticon:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1344"
        case .wallpaper:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1342"
        case .versionPV:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1348"
        case .characterPV:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1339"
        case .characterCombatDemo:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1340"
        case .storyAnimation:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1347"
        case .radioEP:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1341"
        case .radioOST:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1346"
        case .otherMedia:
            urlString =
                "https://wiki.kurobbs.com/mc/catalogue/list?fid=1292&sid=1286"
        }
        return URL(string: urlString)!
    }
}

struct MediaCollectionView: View {
    @State private var viewModel = MediaCollectionViewModel()
    @State private var selectedMediaType: MediaType = .fanArt

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 180))
                    ]) {
                        ForEach(viewModel.items(for: selectedMediaType)) {
                            item in
                            NavigationLink {
                                if let itemId = item.itemId {
                                    if selectedMediaType == .fanArt {
                                        FanArtDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .emoticon {
                                        EmoticonDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .wallpaper {
                                        WallpaperDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .versionPV {
                                        VersionPVDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .characterPV {
                                        // CharacterPVDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .characterCombatDemo {
                                        // CharacterCombatDemoDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .storyAnimation {
                                        // StoryAnimationDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .radioEP {
                                        // RadioEPDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .radioOST {
                                        // RadioOSTDetailsView(itemId: itemId)
                                    } else if selectedMediaType == .otherMedia {
                                        // OtherMediaDetailsView(itemId: itemId)
                                    }
                                }
                            } label: {
                                VStack {
                                    if let cover = item.cover {
                                        KFImage(cover)
                                            .placeholder {
                                                ProgressView()
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 180, height: 90)
                                            .clipShape(.rect(cornerRadius: 10))
                                    }
                                    Text(item.title ?? "")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedMediaType.rawValue)
            .onChange(of: selectedMediaType) { _, newValue in
                viewModel.loadItems(for: newValue)
            }
            .onAppear {
                viewModel.loadItems(for: selectedMediaType)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Picker("媒体类型", selection: $selectedMediaType) {
                        ForEach(MediaType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
}

struct MediaCollectionItem: Identifiable {
    let id = UUID()
    let title: String?
    let cover: URL?
    let itemId: String?
}

@Observable
final class MediaCollectionViewModel {
    var itemsByType: [MediaType: [MediaCollectionItem]] = [:]
    var isLoading = false

    func loadItems(for mediaType: MediaType) {
        // 如果已经加载过该类型的数据，直接返回
        if itemsByType[mediaType] != nil {
            return
        }

        isLoading = true
        MediaCollectionScraper.shared.fetchItems(for: mediaType) {
            [weak self] items in
            self?.itemsByType[mediaType] = items
            self?.isLoading = false
        }
    }

    func items(for mediaType: MediaType) -> [MediaCollectionItem] {
        return itemsByType[mediaType] ?? []
    }
}

class MediaCollectionScraper {
    static let shared = MediaCollectionScraper()

    private let scraper: WebScraper<[MediaCollectionItem]>

    private init() {
        self.scraper = WebScraper(category: "VideoCollectionScraper") {
            doc,
            logger in
            var items: [MediaCollectionItem] = []

            let itemElements = try doc.select("div.entry-wrapper")

            for itemElement in itemElements {
                let title = try itemElement.select("div.card-footer").text()
                let cover = try itemElement.select("div.card-content-inner img")
                    .attr("data-src")
                let url = try itemElement.select("a").attr("href")
                let itemId: String

                if let match = url.range(
                    of: #"/mc/item/(\d+)"#,
                    options: .regularExpression
                ),
                    let idRange = url.range(
                        of: #"\d+"#,
                        options: .regularExpression,
                        range: match
                    )
                {
                    itemId = String(url[idRange])
                } else {
                    itemId = url  // Fallback to full href if regex fails
                }

                let item = MediaCollectionItem(
                    title: title,
                    cover: URL(string: cover),
                    itemId: itemId
                )

                items.append(item)
            }

            return items
        }
    }

    func fetchItems(
        for mediaType: MediaType,
        completion: @escaping ([MediaCollectionItem]) -> Void
    ) {
        scraper.fetch(
            from: mediaType.url,
            completion: completion
        )
    }
}

#Preview {
    MediaCollectionView()
}
