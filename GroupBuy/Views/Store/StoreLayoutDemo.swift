//
//  StoreLayoutDemo.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/20.
//

import SwiftUI

/// 商店佈局展示頁面 - 用於展示不同的商店項目佈局
struct StoreLayoutDemo: View {
    @StateObject private var viewModel = GroupBuyViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    cardGridSection
                    listRowSection
                    featuredStoreSection
                }
                .padding()
            }
            .navigationTitle("佈局展示")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("商店項目佈局展示")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("點擊任一商店項目查看詳細資訊")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Card Grid Section
    private var cardGridSection: some View {
        GroupBox("網格卡片佈局") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(Array(Store.sampleStores.prefix(4))) { store in
                    StoreCardView(
                        store: store,
                        isSelected: false,
                        viewModel: viewModel
                    ) {
                        print("選擇了商店: \(store.name)")
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - List Row Section
    private var listRowSection: some View {
        GroupBox("列表行佈局") {
            VStack(spacing: 8) {
                let stores = Array(Store.sampleStores.prefix(5))
                ForEach(stores, id: \.id) { store in
                    StoreRowView(viewModel: viewModel, store: store)
                    if store != stores.last {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Featured Store Section
    private var featuredStoreSection: some View {
        GroupBox("精選商店") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(Store.sampleStores.suffix(3))) { store in
                        FeaturedStoreCard(store: store, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Featured Store Card
/// 精選商店卡片組件
struct FeaturedStoreCard: View {
    let store: Store
    @ObservedObject var viewModel: GroupBuyViewModel
    @State private var selectedStoreForDetail: Store?
    
    var body: some View {
        Button(action: {
            selectedStoreForDetail = store
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 商店圖示區域
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Store.spotlightColor(for: store.category))
                        .frame(height: 100)
                    
                    Image(systemName: store.imageURL)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                }
                
                // 商店資訊區域
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(store.categoryDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(store.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // 評分區域
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < 4 ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        Text("4.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if store.isCustom {
                            CustomStoreBadge()
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedStoreForDetail) { store in
            NavigationView {
                StoreDetailView(viewModel: viewModel, store: store)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    StoreLayoutDemo()
}
