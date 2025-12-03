//
//  LibraryView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/28.
//

import SDWebImageSwiftUI
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Query
    var items: [Item]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))]) {
                    ForEach(items, id: \.id) { item in
                        VStack {
                            WebImage(url: item.imageURL)
                                .resizable()
                                .scaledToFit()
                                .background(.thinMaterial)
                                .clipShape(.rect(cornerRadius: 10))

                            Text(item.name ?? "")
                                .font(.headline)
                            Text("\(item.tabType) | \(item.subType)")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("收藏夹")
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Item.self)
}
