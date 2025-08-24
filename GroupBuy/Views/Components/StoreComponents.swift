//
//  StoreComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// MARK: - Store Icon View
/// 商店圖示組件，顯示分類對應的圖示和顏色
struct StoreIconView: View {
    let store: Store
    
    var body: some View {
        Image(systemName: Store.spotlightIcon(for: store.category))
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 28, height: 28)
            .background(Store.spotlightColor(for: store.category))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Store Info View  
/// 商店資訊組件，顯示商店名稱、描述和釘選狀態
struct StoreInfoView: View {
    let store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(store.name)
                    .font(.headline)
                if store.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            Text(store.description.isEmpty ? store.address : store.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Custom Store Badge
/// 自訂商店徽章組件
struct CustomStoreBadge: View {
    var body: some View {
        Text("自訂")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.2))
            .foregroundColor(.orange)
            .clipShape(Capsule())
    }
}

// MARK: - Store Card View
/// 商店卡片組件，用於選擇商店的網格視圖
struct StoreCardView: View {
    let store: Store
    let isSelected: Bool
    let onTap: () -> Void
    let viewModel: GroupBuyViewModel?
    @State private var selectedStoreForDetail: Store?
    
    init(store: Store, isSelected: Bool, viewModel: GroupBuyViewModel? = nil, onTap: @escaping () -> Void) {
        self.store = store
        self.isSelected = isSelected
        self.viewModel = viewModel
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: store.imageURL)
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text(store.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(store.categoryDisplayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(store.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if let viewModel = viewModel {
                Button(action: {
                    selectedStoreForDetail = store
                }) {
                    Label("查看詳細資訊", systemImage: "info.circle")
                }
            }
        }
        .sheet(item: $selectedStoreForDetail) { store in
            if let viewModel = viewModel {
                NavigationView {
                    StoreDetailView(viewModel: viewModel, store: store)
                }
            }
        }
    }
}

// MARK: - Store Row View
/// 商店列表行組件，用於商店列表顯示
struct StoreRowView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    let store: Store
    var onSelect: ((Store) -> Void)?
    @State private var selectedStoreForDetail: Store?
    
    // 計算屬性來獲取最新的商店狀態
    private var currentStore: Store {
        viewModel.stores.first(where: { $0.id == store.id }) ?? store
    }
    
    // 便利初始化器，用於瀏覽模式（顯示商店詳細資訊）
    init(viewModel: GroupBuyViewModel, store: Store) {
        self.viewModel = viewModel
        self.store = store
        self.onSelect = nil
    }
    
    // 完整初始化器，用於選擇模式（回傳選擇的商店）
    init(viewModel: GroupBuyViewModel, store: Store, onSelect: @escaping (Store) -> Void) {
        self.viewModel = viewModel
        self.store = store
        self.onSelect = onSelect
    }
    
    var body: some View {
        Button(action: {
            if let onSelect = onSelect {
                // 選擇模式：回傳選擇的商店
                onSelect(store)
            } else {
                // 瀏覽模式：設置要顯示詳細資訊的商店
                selectedStoreForDetail = store
            }
        }) {
            storeRowContent
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing) {
            if store.isCustom {
                Button(role: .destructive) {
                    viewModel.stores.removeAll(where: { $0.id == store.id })
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.toggleStorePin(store)
            } label: {
                Label(currentStore.isPinned ? "取消釘選" : "釘選", systemImage: currentStore.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .sheet(item: $selectedStoreForDetail) { store in
            NavigationView {
                StoreDetailView(viewModel: viewModel, store: store)
            }
        }
    }
    
    private var storeRowContent: some View {
        HStack {
            StoreIconView(store: store)
            StoreInfoView(store: store)
            Spacer()
            if store.isCustom {
                CustomStoreBadge()
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews
#Preview("Store Icon") {
    StoreIconView(store: Store.sampleStores[0])
}

#Preview("Store Info") {
    StoreInfoView(store: Store.sampleStores[0])
}

#Preview("Store Card") {
    StoreCardView(store: Store.sampleStores[0], isSelected: true, viewModel: GroupBuyViewModel()) {
        print("Store selected")
    }
}

#Preview("Store Row") {
    StoreRowView(viewModel: GroupBuyViewModel(), store: Store.sampleStores[0])
}
