//
//  MainTabView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = GroupBuyViewModel()
    @State private var selectedTab = 0
    @State private var showingCreateOrderFromStore = false
    @State private var preselectedStore: Store?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                .tag(0)
            
            OrderListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("我的訂單")
                }
                .tag(1)
            
            StoreListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "storefront.fill")
                    Text("商店")
                }
                .tag(2)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateOrderWithStore"))) { notification in
            if let store = notification.object as? Store {
                preselectedStore = store
                showingCreateOrderFromStore = true
            }
        }
        .sheet(isPresented: $showingCreateOrderFromStore) {
            HostOrderView(viewModel: viewModel, preselectedStore: preselectedStore)
        }
        .onChange(of: showingCreateOrderFromStore) { isShowing in
            // 當 Sheet 關閉時，清理預選商店狀態
            if !isShowing {
                preselectedStore = nil
            }
        }
    }
}
#Preview {
    MainTabView()
}
