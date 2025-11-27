//
//  WallpaperDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/27.
//

import SwiftSoup
import SwiftUI

struct WallpaperDetailsView: View {
    let itemId: String

    @State private var viewModel = WallpaperDetailsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let details = viewModel.details {
                    ForEach(details.characterWallpaperGroups, id: \.id) {
                        characterWallpaperGroup in
                        Section(characterWallpaperGroup.characterName ?? "") {
                            
                        }
                    }
                }
            }
            .navigationTitle(viewModel.details?.title ?? "")
            .onAppear {
                if viewModel.details == nil {
                    viewModel.loadWallpapers(itemId: itemId)
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
final class WallpaperDetailsViewModel {
    var details: WallpaperDetails?
    var isLoading = false

    func loadWallpapers(itemId: String) {
        isLoading = true
        WallpaperDetailsScraper.shared.fetchWallpapers(itemId: itemId) {
            [weak self] details in
            self?.details = details
            self?.isLoading = false
        }
    }
}

struct WallpaperDetails {
    let id = UUID()
    let title: String?
    let characterWallpaperGroups: [CharacterWallpaperGroup]
}

struct CharacterWallpaperGroup {
    let id = UUID()
    let characterName: String?
    let wallpaperGroups: [WallpaperGroup]
}

struct WallpaperGroup {
    let id = UUID()
    let title: String?
    let wallpapers: [Wallpaper]
}

struct Wallpaper {
    let id = UUID()
    let url: URL?
}

class WallpaperDetailsScraper {
    static let shared = WallpaperDetailsScraper()

    private let scraper: WebScraper<WallpaperDetails>

    private init() {
        self.scraper = WebScraper(category: "WallpaperDetailsScraper") {
            doc,
            logger in

            let title = try doc.select(
                "h1"
            ).text()

            let characterWallpaperGroupElements = try doc.select(
                "main > div.module-layout > div"
            )

            var characterWallpaperGroups: [CharacterWallpaperGroup] = []

            for characterWallpaperGroupElement
                in characterWallpaperGroupElements
            {
                var wallpaperGroups: [WallpaperGroup] = []

                let characterName = try characterWallpaperGroupElement.select(
                    "div.module-title"
                ).text()

                let wallpaperGroupElements =
                    try characterWallpaperGroupElement.select(
                        "div.component-container div"
                    )

                for wallpaperGroupElement in wallpaperGroupElements {
                    let title = try wallpaperGroupElement.select(
                        "div.component-title-wrapper"
                    ).text()

                    let wallpaperElements = try wallpaperGroupElement.select(
                        "div.component-content-inner img"
                    )

                    var wallpapers: [Wallpaper] = []

                    for wallpaperElement in wallpaperElements {
                        let url = try wallpaperElement.attr("src")
                        wallpapers.append(Wallpaper(url: URL(string: url)))
                    }

                    let group = WallpaperGroup(
                        title: title,
                        wallpapers: wallpapers
                    )
                    wallpaperGroups.append(group)
                }

                characterWallpaperGroups.append(
                    CharacterWallpaperGroup(
                        characterName: characterName,
                        wallpaperGroups: wallpaperGroups
                    )
                )
            }

            return WallpaperDetails(
                title: title,
                characterWallpaperGroups: characterWallpaperGroups
            )
        }
    }

    func fetchWallpapers(
        itemId: String,
        completion: @escaping (WallpaperDetails) -> Void
    ) {
        scraper.fetch(
            from: URL(
                string: "https://wiki.kurobbs.com/mc/item/\(itemId)"
            )!,
            completion: completion
        )
    }
}

#Preview {
    WallpaperDetailsView(itemId: "1370459724700995584")
}
