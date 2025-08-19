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
#Preview {
    MainTabView()
}
