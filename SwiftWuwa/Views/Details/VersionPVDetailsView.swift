//
//  VersionPVDetailsView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/26.
//

import AVKit
import SwiftSoup
import SwiftUI

struct VersionPVDetailsView: View {
    let itemId: String

    @State private var viewModel = VersionPVDetailsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let player = viewModel.player {
                    Section("正片") {
                        AVPlayerViewControllerRepresentable(player: player)
                            .frame(height: 200)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle(viewModel.versionPVInfo?.title ?? "")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                viewModel.loadVideoInfo(itemId)

            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - AVPlayerViewController Wrapper
#if os(iOS)
    struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
        let player: AVPlayer

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            controller.player = player
            controller.allowsPictureInPicturePlayback = true
            return controller
        }

        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            uiViewController.player = player
        }
    }
#elseif os(macOS)
    struct AVPlayerViewControllerRepresentable: NSViewRepresentable {
        let player: AVPlayer

        func makeNSView(context: Context) -> AVPlayerView {
            let view = AVPlayerView()
            view.player = player
            view.controlsStyle = .floating
            return view
        }

        func updateNSView(_ nsView: AVPlayerView, context: Context) {
            nsView.player = player
        }
    }
#endif

struct VersionPVInfo {
    let title: String?
    let thumbnailURL: URL?
    let videoURL: URL?
}

@Observable
final class VersionPVDetailsViewModel {
    var versionPVInfo: VersionPVInfo?
    var isLoading = false
    var player: AVPlayer?

    func loadVideoInfo(_ itemId: String) {
        isLoading = true
        VersionPVDetailsScraper.shared.fetchVideoInfo(itemId: itemId) {
            [weak self] info in
            self?.versionPVInfo = info
            if let videoURL = info.videoURL {
                self?.player = AVPlayer(url: videoURL)
                self?.isLoading = false
            }
        }
    }
}

class VersionPVDetailsScraper {
    static let shared = VersionPVDetailsScraper()

    private let scraper: WebScraper<VersionPVInfo>

    private init() {
        self.scraper = WebScraper(category: "VersionPVDetailsScraper") {
            doc,
            logger in
            let pvElement = try doc.select("video")

            let title = try doc.select("h1").text()
            let pvVideoURL = try pvElement.attr("src")

            return VersionPVInfo(
                title: title,
                thumbnailURL: nil,
                videoURL: URL(string: pvVideoURL)
            )
        }
    }

    func fetchVideoInfo(
        itemId: String,
        completion: @escaping (VersionPVInfo) -> Void
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
    VersionPVDetailsView(itemId: "1439039318269669376")
}
