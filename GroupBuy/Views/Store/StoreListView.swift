//
//  StoreListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

struct StoreListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @State private var showingCustomStore = false
    @State private var searchText = ""
    @StateObject private var speechManager = SpeechRecognitionManager()
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(
                    searchText: $searchText,
                    speechManager: speechManager,
                    placeholder: "搜尋商店名稱",
                    isSearching: false,
                    onSearchSubmit: {
                        isSearchFieldFocused = false
                    },
                    onSearchTextChange: { newText in
                        searchText = newText
                    }
                )
                .focused($isSearchFieldFocused)
                .padding(.vertical, 8)
                
                StoreListContent(
                    viewModel: viewModel,
                    searchText: searchText,
                    isSearchFieldFocused: $isSearchFieldFocused
                )
            }
            .navigationTitle("商店列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增商店") {
                        showingCustomStore = true
                    }
                }
            }
            .sheet(isPresented: $showingCustomStore) {
                StoreFormView(viewModel: viewModel)
            }
            .onReceive(speechManager.$recognizedText) { text in
                if !text.isEmpty {
                    searchText = text
                }
            }
        }
    }
}

// MARK: - StoreSearchBar 已移除，直接使用 SearchBarView 組件

private struct StoreListContent: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    let searchText: String
    @FocusState.Binding var isSearchFieldFocused: Bool
    
    // 使用計算屬性簡化商店過濾邏輯
    private var storeGroups: StoreGroups {
        StoreGroups(stores: viewModel.stores, searchText: searchText)
    }
    
    var body: some View {
        List {
            // 釘選的商店
            if !storeGroups.pinned.isEmpty {
                PinnedStoresSection(stores: storeGroups.pinned, viewModel: viewModel)
            }
            
            // 按分類顯示的商店
            CategoryStoresSection(storeGroups: storeGroups, viewModel: viewModel)
            
            // 空狀態
            if storeGroups.isEmpty {
                EmptyStoresView(searchText: searchText)
            }
        }
        .dismissKeyboardOnScroll(focus: $isSearchFieldFocused)
    }
}

private struct PinnedStoresSection: View {
    let stores: [Store]
    @ObservedObject var viewModel: GroupBuyViewModel
    
    var body: some View {
        Section {
            ForEach(stores) { store in
                StoreRowView(viewModel: viewModel, store: store)
                    .id("\(store.id)-pinned")
            }
        } header: {
            HStack {
                Image(systemName: "pin.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("釘選的商店")
            }
        }
    }
}

private struct CategoryStoresSection: View {
    let storeGroups: StoreGroups
    @ObservedObject var viewModel: GroupBuyViewModel
    
    var body: some View {
        // 自訂商店
        if !storeGroups.customStores.isEmpty {
            Section("自訂") {
                ForEach(storeGroups.customStores) { store in
                    StoreRowView(viewModel: viewModel, store: store)
                        .id("\(store.id)-unpinned")
                }
            }
        }
        
        // 分類商店
        ForEach(Store.commonCategories, id: \.self) { category in
            let categoryStores = storeGroups.storesByCategory[category.rawValue] ?? []
            if !categoryStores.isEmpty {
                Section(Store.categoryDisplayName(for: category)) {
                    ForEach(categoryStores) { store in
                        StoreRowView(viewModel: viewModel, store: store)
                            .id("\(store.id)-unpinned")
                    }
                }
            }
        }
    }
}

private struct EmptyStoresView: View {
    let searchText: String
    
    var body: some View {
        if !searchText.isEmpty {
            Section {
                EmptyStateView.noSearchResults(searchText: searchText)
                    .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Store Groups Helper

private struct StoreGroups {
    let pinned: [Store]
    let customStores: [Store]
    let storesByCategory: [String: [Store]]
    let isEmpty: Bool
    
    init(stores: [Store], searchText: String) {
        let filtered = searchText.isEmpty ? stores : stores.filter { store in
            store.name.localizedCaseInsensitiveContains(searchText) ||
            store.description.localizedCaseInsensitiveContains(searchText) ||
            store.address.localizedCaseInsensitiveContains(searchText)
        }
        
        self.pinned = filtered.filter { $0.isPinned }
        
        let unpinned = filtered.filter { !$0.isPinned }
        self.customStores = unpinned.filter { $0.category == nil }
        
        var categoryDict: [String: [Store]] = [:]
        for category in Store.commonCategories {
            let categoryStores = unpinned.filter { $0.category == category }
            if !categoryStores.isEmpty {
                categoryDict[category.rawValue] = categoryStores
            }
        }
        self.storesByCategory = categoryDict
        
        self.isEmpty = !searchText.isEmpty && filtered.isEmpty
    }
}

// MARK: - Store Row組件已移至 StoreComponents.swift

#Preview {
    StoreListView(viewModel: GroupBuyViewModel())
}
