import Combine
import Kingfisher
import SwiftUI

@Observable
class EncyclopediaViewModel {
    var previewItems: [EncyclopediaCategory: [EncyclopediaPreviewItem]] = [:]
    var isLoading = false
    var selectedCategory: EncyclopediaCategory = .characters

    /// Get preview items for the currently selected category
    var currentItems: [EncyclopediaPreviewItem] {
        previewItems[selectedCategory] ?? []
    }

    func loadEntries(forceRefresh: Bool = false) {
        isLoading = true
        EncyclopediaScraper.shared.fetchEntries(
            category: selectedCategory,
            forceRefresh: forceRefresh
        ) { [weak self] fetchedCharacters in
            guard let self = self else { return }
            self.previewItems[self.selectedCategory] = fetchedCharacters
            self.isLoading = false
        }
    }

    func refresh() {
        loadEntries(forceRefresh: true)
    }

    func changeCategory(_ category: EncyclopediaCategory) {
        selectedCategory = category
        // Only load if we don't have cached data for this category
        if previewItems[category] == nil {
            loadEntries()
        }
    }
}

struct EncyclopediaView: View {
    @State private var viewModel = EncyclopediaViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100, maximum: 128))],
                    spacing: 10
                ) {
                    ForEach(viewModel.currentItems) { previewItem in
                        NavigationLink {
                            if viewModel.selectedCategory == .characters {
                                CharacterDetailsView(
                                    characterId: previewItem.itemId
                                )
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack {
                                    if let url = previewItem.imageURL {
                                        KFImage(url)
                                            .placeholder {
                                                ProgressView()
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .background(.regularMaterial)
                                            .clipShape(.rect(cornerRadius: 10))
                                    }
                                    Text(previewItem.name)
                                        .font(.headline)
                                }
                                if let skillAttrURL = previewItem.skillAttrURL {
                                    KFImage(skillAttrURL)
                                        .placeholder {
                                            Image(systemName: "star")
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    viewModel.refresh()
                    // Wait a bit for the refresh to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume()
                    }
                }
            }
            .navigationTitle(viewModel.selectedCategory.rawValue)
            .toolbar {
                ToolbarItem {
                    Menu {
                        Picker(selection: $viewModel.selectedCategory) {
                            ForEach(EncyclopediaCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        } label: {
                            Label("分类", systemImage: "square.grid.2x2")
                        }
                        .onChange(of: viewModel.selectedCategory) {
                            _,
                            newValue in
                            viewModel.changeCategory(newValue)
                        }
                    } label: {
                        Label("选项", systemImage: "ellipsis")
                    }
                }
            }
            .onAppear {
                if viewModel.currentItems.isEmpty {
                    viewModel.loadEntries()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                }
            }
        }
    }
}

struct WikiListView_Preview: View {
    @State private var viewModel = EncyclopediaViewModel()

    var body: some View {
        EncyclopediaView()
    }
}

#Preview {
    WikiListView_Preview()
}
