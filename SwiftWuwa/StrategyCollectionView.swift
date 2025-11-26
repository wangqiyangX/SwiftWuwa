//
//  StrategyCollectionView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/25.
//

import Kingfisher
import SwiftSoup
import SwiftUI

struct StrategyCollectionView: View {
    @State private var viewModel = StrategyCollectionViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 260))
                ]) {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            if let itemId = item.itemId {
                                CharacterGuideView(characterId: itemId)
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
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                Text(item.title ?? "")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("角色攻略")
            .onAppear {
                viewModel.loadItems()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("加载中")
                }
            }
        }
    }
}

@Observable
final class StrategyCollectionViewModel {
    var items: [StrategyCollectionItem] = []
    var isLoading = false

    func loadItems() {
        isLoading = true
        StrategyCollectionScraper.shared.fetchItems { [weak self] items in
            self?.items = items
            self?.isLoading = false
        }
    }
}

struct StrategyCollectionItem: Identifiable {
    let id = UUID()
    let title: String?
    let cover: URL?
    let itemId: String?
}

class StrategyCollectionScraper {
    static let shared = StrategyCollectionScraper()

    private let scraper: WebScraper<[StrategyCollectionItem]>

    private init() {
        self.scraper = WebScraper(category: "StrategyCollectionScraper") {
            doc,
            logger in
            var items: [StrategyCollectionItem] = []
            if let itemElements = try? doc.select("div.entry-wrapper") {
                for itemElement in itemElements {
                    let title = try? itemElement.select("div.card-footer")
                        .text()
                    let cover = try? itemElement.select(
                        "div.card-content-inner img"
                    ).attr(
                        "data-src"
                    )
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
                    let item = StrategyCollectionItem(
                        title: title,
                        cover: URL(string: cover ?? ""),
                        itemId: itemId
                    )

                    items.append(item)
                }

                return items
            } else {
                return []
            }
        }
    }

    func fetchItems(completion: @escaping ([StrategyCollectionItem]) -> Void) {
        scraper.fetch(
            from: URL(
                string: "https://wiki.kurobbs.com/mc/catalogue/list?fid=1322"
            )!,
            completion: completion
        )
    }
}

#Preview {
    StrategyCollectionView()
}
