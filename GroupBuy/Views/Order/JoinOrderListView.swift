//
//  JoinOrderListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct JoinOrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    // optional initial filter passed from other views (e.g. StatisticView)
    var initialFilter: FilterOption? = nil
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var searchText = ""
    @State private var selectedFilterOption: FilterOption = .all
    @State private var isRefreshing = false
    @State private var selectedOrder: GroupBuyOrder?
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    // MARK: - Computed Properties
    private var filteredOrders: [GroupBuyOrder] {
        viewModel.getFilteredOrders(
            searchText: searchText,
            filter: selectedFilterOption
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋和篩選區域
                SearchAndFilterSection(
                    searchText: $searchText,
                    selectedFilter: $selectedFilterOption,
                    speechManager: speechManager
                )
                
                // 主要內容
                MainContentView(
                    orders: filteredOrders,
                    searchText: searchText,
                    viewModel: viewModel,
                    isRefreshing: $isRefreshing,
                    dismiss: dismiss,
                    selectedOrder: $selectedOrder
                )
            }
            .navigationTitle("參加團購")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    RefreshButton(isRefreshing: $isRefreshing) {
                        await refreshOrders()
                    }
                }
            }
        }
        .onAppear {
            if let initial = initialFilter {
                selectedFilterOption = initial
            }
        }
        .sheet(item: $selectedOrder) { order in
            OrderDetailSheet(order: order, viewModel: viewModel, selectedOrder: $selectedOrder)
        }
        .onAppear {
            setupSpeechRecognition()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Private Methods
    private func setupSpeechRecognition() {
        speechManager.onRecognitionComplete = { [weak speechManager] recognizedText in
            searchText = recognizedText
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @MainActor
    private func refreshOrders() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        // 模擬網路請求延遲
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 這裡可以加入實際的資料重新載入邏輯
        // await viewModel.refreshActiveOrders()
        // 手動觸發全域時間更新，讓時間標籤立即刷新
        viewModel.now = Date()
    }
}

// MARK: - Order Detail Sheet
private struct OrderDetailSheet: View {
    let order: GroupBuyOrder
    let viewModel: GroupBuyViewModel
    @Binding var selectedOrder: GroupBuyOrder?
    
    var body: some View {
        NavigationView {
            OrderDetailView(order: order, viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("關閉") {
                            selectedOrder = nil
                        }
                    }
                }
        }
    }
}

#Preview("JoinOrderListView") {
    JoinOrderListView(viewModel: {
        let viewModel = GroupBuyViewModel()
        
        // 建立一些 User 作為示例
        let user = User.sampleUser // User 是當前用戶
        let userXiaoMing = User(name: "小明", email: "ming@example.com")
        let userXiaoHua = User(name: "小華", email: "hua@example.com")
        let userXiaoMei = User(name: "小美", email: "mei@example.com")
        let userXiaoWang = User(name: "小王", email: "wang@example.com")
        let userXiaoChen = User(name: "小陳", email: "chen@example.com")

        viewModel.activeOrders = [
            GroupBuyOrder(
                title: "🍱 午餐團購 - 池上便當",
                store: Store.sampleStores[2],
                organizer: user, // user 是建立者
                endTime: Date().addingTimeInterval(1800), // 30分鐘後
                notes: "請在備註欄註明要不要辣椒和泡菜",
                participants: [
                    Participant(
                        user: user, 
                        items: [
                            OrderItem(name: "排骨便當", price: 85, notes: "要辣椒")
                        ], 
                        notes: "加辣", 
                        joinedAt: Date()
                    ),
                    Participant(
                        user: userXiaoMei,
                        items: [
                            OrderItem(name: "雞腿便當", price: 90, quantity: 1, notes: "不要泡菜"),
                            OrderItem(name: "冬瓜茶", price: 20, quantity: 2)
                        ],
                        notes: "分兩個便當袋",
                        joinedAt: Date()
                    )
                ],
                isPublic: true,
                status: .active,
                createdAt: Date().addingTimeInterval(-600)
            ),
            GroupBuyOrder(
                title: "🧋 下午茶時間 - 50嵐",
                store: Store.sampleStores[1],
                organizer: userXiaoWang,
                endTime: Date().addingTimeInterval(3600), // 1小時後
                notes: "甜度冰塊請在備註欄說明",
                participants: [], // 無人參加
                isPublic: true,
                status: .active,
                createdAt: Date().addingTimeInterval(-300)
            ),
            GroupBuyOrder(
                title: "☕️ 咖啡提神 - 星巴克",
                store: Store.sampleStores[0],
                organizer: user, // user 也是這個的建立者
                endTime: Date().addingTimeInterval(7200), // 2小時後
                notes: "有需要加燕麥奶的請備註",
                participants: [
                    Participant(
                        user: userXiaoChen,
                        items: [
                            OrderItem(name: "美式咖啡", price: 120, quantity: 1, notes: "大杯"),
                            OrderItem(name: "起司蛋糕", price: 85, quantity: 1)
                        ],
                        notes: "要袋子",
                        joinedAt: Date()
                    )
                ], // user 建立但未參加
                isPublic: false,
                status: .active,
                createdAt: Date().addingTimeInterval(-900)
            )
        ]

        return viewModel
    }())
}

#Preview("Empty State") {
    JoinOrderListView(viewModel: {
        let vm = GroupBuyViewModel()
        vm.activeOrders = []
        return vm
    }())
}
