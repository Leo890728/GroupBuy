//
//  HomeView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @State private var showingCreateOrder = false
    @State private var showingJoinOrder = false
    @State private var showingCustomStore = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo 和標題
                AppHeaderView()

                // 底部統計資訊
                StatisticSectionView(viewModel: viewModel)
                
                // 主要功能按鈕
                MainMenuSection(
                    showingCreateOrder: $showingCreateOrder,
                    showingJoinOrder: $showingJoinOrder,
                    showingCustomStore: $showingCustomStore
                )
            }
            .navigationTitle("首頁")
            .navigationBarTitleDisplayMode(.large)
                                .sheet(isPresented: $showingJoinOrder) {
                        JoinOrderListView(viewModel: viewModel)
                    }
                    .sheet(isPresented: $showingCreateOrder) {
                        CreateOrderView(viewModel: viewModel)
                    }
            .sheet(isPresented: $showingCustomStore) {
                StoreFormView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Sub Components

private struct AppHeaderView: View {
    var body: some View {
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
    }
}

private struct StatisticSectionView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            StatisticView(
                title: "進行中",
                value: "\(viewModel.getActiveOrders().count)",
                icon: "clock.fill"
            )
            StatisticView(
                title: "商店數",
                value: "\(viewModel.stores.count)",
                icon: "storefront.fill"
            )
        }
        .padding(.bottom, 10)
    }
}

private struct MainMenuSection: View {
    @Binding var showingCreateOrder: Bool
    @Binding var showingJoinOrder: Bool
    @Binding var showingCustomStore: Bool
    
    var body: some View {
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
}

#Preview {
    HomeView(viewModel: GroupBuyViewModel())
}
