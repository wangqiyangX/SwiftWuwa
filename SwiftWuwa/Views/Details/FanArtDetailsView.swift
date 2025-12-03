//
//  FanArtDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/26.
//

import Kingfisher
import SwiftSoup
import SwiftUI

struct FanArtDetailsView: View {
    let itemId: String

    @State private var viewModel = FanArtDetailsViewModel()
    @State private var showFullScreen = false

    var body: some View {
        NavigationStack {
            TabView {
                ForEach(viewModel.images, id: \.self) { image in
                    KFImage(image)
                        .placeholder {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .navigationTitle("同人绘画")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .tabViewStyle(.page)
            #endif
            .onAppear {
                if viewModel.images.isEmpty {
                    viewModel.loadImages(itemId: itemId)
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
final class FanArtDetailsViewModel {
    var images: [URL?] = []
    var isLoading = false

    func loadImages(itemId: String) {
        isLoading = true
        FanArtDetailsScraper.shared.fetchImages(itemId: itemId) {
            [weak self] images in
            self?.images = images
            self?.isLoading = false
        }
    }
}

class FanArtDetailsScraper {
    static let shared = FanArtDetailsScraper()

    private let scraper: WebScraper<[URL?]>

    private init() {
        self.scraper = WebScraper(category: "FanArtDetailsScraper") {
            doc,
            logger in
            let imageElements = try doc.select("div.component-content-text")
            var images: [URL?] = []
            for imageElement in imageElements {
                let imageURL = try imageElement.select("img").attr("src")
                images.append(URL(string: imageURL))
            }
            return images
        }
    }

    func fetchImages(itemId: String, completion: @escaping ([URL?]) -> Void) {
        scraper.fetch(
            from: URL(
                string: "https://wiki.kurobbs.com/mc/item/\(itemId)"
            )!,
            completion: completion
        )
    }
}

#Preview {
    FanArtDetailsView(itemId: "1438636250121265152")
}
