//
//  EmoticonDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/27.
//

import SDWebImageSwiftUI
import SwiftSoup
import SwiftUI

struct EmoticonDetailsView: View {
    let itemId: String

    @State private var viewModel = EmoticonDetailsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(viewModel.details?.emoticons ?? [], id: \.id) {
                        emoticon in
                        WebImage(url: emoticon.url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .background(.thinMaterial)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.details?.title ?? "")
            .onAppear {
                if viewModel.details == nil {
                    viewModel.loadEmoticons(itemId: itemId)
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
final class EmoticonDetailsViewModel {
    var details: EmoticonDetails?
    var isLoading = false

    func loadEmoticons(itemId: String) {
        isLoading = true
        EmoticonDetailsScraper.shared.fetchEmoticons(itemId: itemId) {
            [weak self] details in
            self?.details = details
            self?.isLoading = false
        }
    }
}

class EmoticonDetailsScraper {
    static let shared = EmoticonDetailsScraper()

    private let scraper: WebScraper<EmoticonDetails>

    private init() {
        self.scraper = WebScraper(category: "EmoticonDetailsScraper") {
            doc,
            logger in

            let emoticonElements = try doc.select(
                "main > div.module-layout > div > div.component-container > div > div > div.component-content.component-content-basic-component > div > div > table img"
            )

            var emoticons: [Emoticon] = []

            for element in emoticonElements {
                let url = try element.attr("src")
                emoticons.append(Emoticon(url: URL(string: url)))
            }

            let title = try doc.select(
                "h1"
            ).text()

            return EmoticonDetails(title: title, emoticons: emoticons)
        }
    }

    func fetchEmoticons(
        itemId: String,
        completion: @escaping (EmoticonDetails) -> Void
    ) {
        scraper.fetch(
            from: URL(
                string: "https://wiki.kurobbs.com/mc/item/\(itemId)"
            )!,
            completion: completion
        )
    }
}

struct EmoticonDetails {
    let title: String?
    let emoticons: [Emoticon]
}

struct Emoticon {
    let id = UUID()
    let url: URL?
}

#Preview {
    EmoticonDetailsView(itemId: "1427069586296147968")
}
