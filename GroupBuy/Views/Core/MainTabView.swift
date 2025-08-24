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
                    Text("我的團購")
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
        // 從 Home 的統計卡點擊來的通知：切換到我的團購並設定初始 scope
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMyOrders"))) { notification in
            if let obj = notification.object as? String {
                switch obj {
                case "hosted":
                    selectedTab = 1
                    // 重新建立 OrderListView 會在 onAppear 處理 initialSelectionScope
                    // 透過 updating selection via NotificationCenter 也是可行的，但這裡用最小入侵方式：發布另一個通知帶範圍，OrderListView 也可監聽
                    NotificationCenter.default.post(name: NSNotification.Name("SetOrderListScope"), object: "hosted")
                case "joined":
                    selectedTab = 1
                    NotificationCenter.default.post(name: NSNotification.Name("SetOrderListScope"), object: "joined")
                default:
                    break
                }
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
