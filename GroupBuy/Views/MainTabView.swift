//
//  MainTabView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = GroupBuyViewModel()
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
            
            OrderListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("我的訂單")
                }
            
            StoreListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "storefront.fill")
                    Text("商店")
                }
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @State private var showingCreateOrder = false
    @State private var showingJoinOrder = false
    @State private var showingCustomStore = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo 和標題
                VStack(spacing: 16) {
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("團購小幫手")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("讓訂餐變得更簡單")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 底部統計資訊
                HStack(spacing: 40) {
                    StatisticView(title: "進行中", value: "\(viewModel.getActiveOrders().count)", icon: "clock.fill")
                    StatisticView(title: "商店數", value: "\(viewModel.stores.count)", icon: "storefront.fill")
                }
                .padding(.bottom, 10)
                
                // 主要功能按鈕
                VStack(spacing: 20) {
                    MainMenuButton(
                        title: "發起團購",
                        subtitle: "建立新的團購訂單",
                        icon: "plus.circle.fill",
                        color: .blue
                    ) {
                        showingCreateOrder = true
                    }
                    
                    MainMenuButton(
                        title: "參加團購",
                        subtitle: "加入現有的團購",
                        icon: "person.2.fill",
                        color: .green
                    ) {
                        showingJoinOrder = true
                    }
                    
                    MainMenuButton(
                        title: "自訂商店",
                        subtitle: "新增您喜愛的店家",
                        icon: "bag.badge.plus",
                        color: .orange
                    ) {
                        showingCustomStore = true
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("首頁")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateOrder) {
                CreateOrderView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingJoinOrder) {
                JoinOrderView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCustomStore) {
                CustomStoreView(viewModel: viewModel)
            }
        }
    }
}

struct OrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.activeOrders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("還沒有訂單")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.activeOrders) { order in
                        OrderRowView(order: order)
                    }
                }
            }
            .navigationTitle("我的訂單")
        }
    }
}

struct OrderRowView: View {
    let order: GroupBuyOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.title)
                    .font(.headline)
                Spacer()
                Text(order.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Text(order.store.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("發起人: \(order.organizer)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StoreListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @State private var showingCustomStore = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Store.StoreCategory.allCases, id: \.self) { category in
                    let storesInCategory = viewModel.stores.filter { $0.category == category }
                    if !storesInCategory.isEmpty {
                        Section(category.rawValue) {
                            ForEach(storesInCategory) { store in
                                StoreRowView(viewModel: viewModel, store: store)
                            }
                        }
                    }
                }
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
                CustomStoreView(viewModel: viewModel)
            }
        }
    }
}

struct StoreRowView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    let store: Store
    
    var body: some View {
        HStack {
            Image(systemName: store.imageURL)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.headline)
                Text(store.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if store.isCustom {
                Text("自訂")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) { // 往左滑
            Button(role: .destructive) {
                viewModel.stores.removeAll(where: { $0.id == store.id })
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    MainTabView()
}
