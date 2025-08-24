//
//  StoreListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

struct StoreListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Binding var selectedStore: Store?
    @Environment(\.dismiss) private var dismiss
    @State private var showingCustomStore = false
    @State private var searchText = ""
    @StateObject private var speechManager = SpeechRecognitionManager()
    @FocusState private var isSearchFieldFocused: Bool
    
    // 用於區分模式的標記
    private let isSelectionMode: Bool
    
    // 便利初始化器，用於非選擇模式
    init(viewModel: GroupBuyViewModel) {
        self.viewModel = viewModel
        self._selectedStore = .constant(nil)
        self.isSelectionMode = false
    }
    
    // 完整初始化器，用於選擇模式
    init(viewModel: GroupBuyViewModel, selectedStore: Binding<Store?>) {
        self.viewModel = viewModel
        self._selectedStore = selectedStore
        self.isSelectionMode = true
    }
    
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
                    isSearchFieldFocused: $isSearchFieldFocused,
                    onSelect: isSelectionMode ? { store in
                        selectedStore = store
                        dismiss()
                    } : nil
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
    var onSelect: ((Store) -> Void)?

    private var storeGroups: StoreGroups {
        StoreGroups(stores: viewModel.stores, searchText: searchText)
    }

    var body: some View {
        List {
            // 釘選的商店
            if !storeGroups.pinned.isEmpty {
                PinnedStoresSection(
                    stores: storeGroups.pinned, 
                    viewModel: viewModel, 
                    onSelect: onSelect
                )
            }

            // 按分類顯示的商店
            CategoryStoresSection(
                storeGroups: storeGroups, 
                viewModel: viewModel, 
                onSelect: onSelect
            )

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
    var onSelect: ((Store) -> Void)?

    var body: some View {
        Section {
            ForEach(stores) { store in
                if let onSelect = onSelect {
                    StoreRowView(
                        viewModel: viewModel, 
                        store: store, 
                        onSelect: onSelect
                    )
                    .id("\(store.id)-pinned")
                } else {
                    StoreRowView(viewModel: viewModel, store: store)
                        .id("\(store.id)-pinned")
                }
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
    var onSelect: ((Store) -> Void)?

    var body: some View {
        // 自訂商店
        if !storeGroups.customStores.isEmpty {
            Section("自訂") {
                ForEach(storeGroups.customStores) { store in
                    if let onSelect = onSelect {
                        StoreRowView(
                            viewModel: viewModel, 
                            store: store, 
                            onSelect: onSelect
                        )
                        .id("\(store.id)-unpinned")
                    } else {
                        StoreRowView(viewModel: viewModel, store: store)
                            .id("\(store.id)-unpinned")
                    }
                }
            }
        }

        // 分類商店
        ForEach(Store.commonCategories, id: \.self) { category in
            let categoryStores = storeGroups.storesByCategory[category.rawValue] ?? []
            if !categoryStores.isEmpty {
                Section(Store.categoryDisplayName(for: category)) {
                    ForEach(categoryStores) { store in
                        if let onSelect = onSelect {
                            StoreRowView(
                                viewModel: viewModel, 
                                store: store, 
                                onSelect: onSelect
                            )
                            .id("\(store.id)-unpinned")
                        } else {
                            StoreRowView(viewModel: viewModel, store: store)
                                .id("\(store.id)-unpinned")
                        }
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
    Group {
        // 瀏覽模式
        StoreListView(viewModel: GroupBuyViewModel())
        
        // 選擇模式
        StoreListView(viewModel: GroupBuyViewModel(), selectedStore: .constant(nil))
    }
}
