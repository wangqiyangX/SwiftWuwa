//
//  ContentView.swift
//  SwiftWuwa
//
//  Created by wangqiyang on 2025/11/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        TabView {
            Tab("收藏夹", systemImage: "tray") {
                LibraryView()
            }
            Tab("游戏图鉴", systemImage: "plus.square.on.square") {
                EncyclopediaView()
            }
            Tab("攻略合集", systemImage: "book") {
                StrategyCollectionView()
            }
            Tab("影像合集", systemImage: "photo.on.rectangle") {
                MediaCollectionView()
            }
            Tab("设置", systemImage: "gearshape") {
                Text("设置")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
