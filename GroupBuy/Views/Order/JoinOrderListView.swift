//
//  JoinOrderListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct JoinOrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilterOption: FilterOption = .all
    @State private var isRefreshing = false
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    // MARK: - 計算屬性優化
    private var filteredOrders: [GroupBuyOrder] {
        viewModel.getFilteredOrders(
            searchText: searchText,
            filter: selectedFilterOption
        )
    }
    
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
                    dismiss: dismiss
                )
            }
            .navigationTitle("參加團購")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    RefreshButton(isRefreshing: $isRefreshing)
                }
            }
        }
        .onAppear {
            setupSpeechRecognition()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Helper Methods
    private func setupSpeechRecognition() {
        speechManager.onRecognitionComplete = { [weak speechManager] recognizedText in
            searchText = recognizedText
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Refresh Button
private struct RefreshButton: View {
    @Binding var isRefreshing: Bool
    
    var body: some View {
        Button {
            Task {
                await refreshOrders()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
        }
        .disabled(isRefreshing)
        .animation(.easeInOut(duration: 1.0).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
    }
    
    private func refreshOrders() async {
        isRefreshing = true
        
        // 模擬網路請求延遲
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 這裡可以加入實際的資料重新載入邏輯
        
        await MainActor.run {
            isRefreshing = false
        }
    }
}

// MARK: - Main Content View
private struct MainContentView: View {
    let orders: [GroupBuyOrder]
    let searchText: String
    let viewModel: GroupBuyViewModel
    @Binding var isRefreshing: Bool
    let dismiss: DismissAction
    
    var body: some View {
        Group {
            if orders.isEmpty {
                EmptyContentView(searchText: searchText, dismiss: dismiss)
            } else {
                OrderListContent(
                    orders: orders,
                    viewModel: viewModel,
                    isRefreshing: $isRefreshing
                )
            }
        }
    }
}

// MARK: - Empty Content View
private struct EmptyContentView: View {
    let searchText: String
    let dismiss: DismissAction
    
    var body: some View {
        if searchText.isEmpty {
            EmptyStateView.noActiveOrders {
                dismiss()
            }
        } else {
            EmptyStateView.noSearchResults(searchText: searchText)
        }
    }
}

// MARK: - Search and Filter Section
private struct SearchAndFilterSection: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FilterOption
    @ObservedObject var speechManager: SpeechRecognitionManager
    
    var body: some View {
        VStack {
            // 搜尋欄
            SearchBarView(
                searchText: $searchText,
                speechManager: speechManager,
                placeholder: "搜尋團購、商店或發起人",
                isSearching: false,
                onSearchSubmit: { },
                onSearchTextChange: { _ in }
            )
            
            // 篩選選項
            FilterOptionsView(selectedFilter: $selectedFilter)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Filter Options View
private struct FilterOptionsView: View {
    @Binding var selectedFilter: FilterOption
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    FilterButton(
                        option: option,
                        isSelected: selectedFilter == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = option
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 44)
    }
}

// MARK: - Filter Button
private struct FilterButton: View {
    let option: FilterOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.caption)
                Text(option.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor : Color(.systemGray6)
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order List Content
private struct OrderListContent: View {
    let orders: [GroupBuyOrder]
    let viewModel: GroupBuyViewModel
    @Binding var isRefreshing: Bool
    
    var body: some View {
        List {
            // 訂單統計資訊
            OrderSummaryCard(orderCount: orders.count)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            // 訂單列表
            OrderListSection(orders: orders, viewModel: viewModel)
        }
        .listStyle(PlainListStyle())
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await refreshData()
        }
    }
    
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - Order List Section
private struct OrderListSection: View {
    let orders: [GroupBuyOrder]
    let viewModel: GroupBuyViewModel
    
    var body: some View {
        ForEach(orders) { order in
            NavigationLink(destination: OrderDetailView(order: order, viewModel: viewModel)) {
                EnhancedOrderCardView(order: order, viewModel: viewModel)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

// MARK: - Enhanced Order Card View
private struct EnhancedOrderCardView: View {
    let order: GroupBuyOrder
    let viewModel: GroupBuyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題和狀態
            OrderHeaderView(order: order)
            
            // 發起人和時間資訊
            OrderInfoView(order: order)
            
            HStack {
                // 備註（如果有的話）
                if !order.notes.isEmpty {
                    OrderNotesView(notes: order.notes)
                }
                // 參與指示器
                ParticipationIndicator(order: order, userManager: viewModel.userManager)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

// MARK: - Time Helper
private enum TimeHelper {
    static func formatTimeRemaining(from endTime: Date) -> (remaining: String, color: Color) {
        let timeInterval = endTime.timeIntervalSinceNow
        
        let remaining: String
        if timeInterval <= 0 {
            remaining = "已結束"
        } else {
            let hours = Int(timeInterval / 3600)
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            remaining = hours > 0 ? "\(hours)小時\(minutes)分鐘" : "\(minutes)分鐘"
        }
        
        let color: Color
        if timeInterval <= 1800 { // 30分鐘內
            color = .red
        } else if timeInterval <= 3600 { // 1小時內
            color = .orange
        } else {
            color = .green
        }
        
        return (remaining, color)
    }
}

// MARK: - Order Card Sub-components
private struct OrderHeaderView: View {
    let order: GroupBuyOrder
    
    private var timeInfo: (remaining: String, color: Color) {
        TimeHelper.formatTimeRemaining(from: order.endTime)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                StoreInfoLabel(store: order.store)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                TimeRemainingLabel(timeInfo: timeInfo)
                ParticipantCountLabel(count: order.participants.count)
            }
        }
    }
}

// MARK: - Micro Components
private struct StoreInfoLabel: View {
    let store: Store
    
    var body: some View {
        HStack {
            Image(systemName: store.spotlightIcon)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(store.spotlightColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(store.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct TimeRemainingLabel: View {
    let timeInfo: (remaining: String, color: Color)
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundColor(timeInfo.color)
            
            Text(timeInfo.remaining)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(timeInfo.color)
        }
    }
}

private struct ParticipantCountLabel: View {
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count) 人")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct OrderInfoView: View {
    let order: GroupBuyOrder
    
    var body: some View {
        HStack {
            Label(order.organizer.name, systemImage: "person.circle.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("結束於 \(order.endTime, style: .time)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct OrderNotesView: View {
    let notes: String
    
    var body: some View {
        Text(notes)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .lineLimit(3)
    }
}

private struct ParticipationIndicator: View {
    let order: GroupBuyOrder
    @ObservedObject var userManager: UserManager

    private var isOrganizer: Bool {
        guard let currentUser = userManager.currentUser else { return false }
        return order.organizer.id == currentUser.id
    }

    var body: some View {
        HStack {
            Spacer()

            if userManager.isParticipatingInOrder(order) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text(isOrganizer ? "已參加 (建立者)" : "已參加")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: isOrganizer ? "crown.fill" : "arrow.right.circle.fill")
                        .foregroundColor(isOrganizer ? .orange : .accentColor)

                    Text(isOrganizer ? "點擊參加 (建立者)" : "點擊參加")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isOrganizer ? .orange : .accentColor)
                }
            }
        }
    }
}

// MARK: - OrderCardView 已移至 OrderComponents.swift

#Preview("JoinOrderListView") {
    JoinOrderListView(viewModel: {
        let viewModel = GroupBuyViewModel()
        
        // 建立一些 User 作為示例
        let userLeo = User.sampleUser // Leo 是當前用戶
        let userXiaoMing = User(name: "小明", email: "ming@example.com")
        let userXiaoHua = User(name: "小華", email: "hua@example.com")
        let userXiaoMei = User(name: "小美", email: "mei@example.com")
        let userXiaoWang = User(name: "小王", email: "wang@example.com")
        let userXiaoChen = User(name: "小陳", email: "chen@example.com")

        viewModel.activeOrders = [
            GroupBuyOrder(
                title: "🍱 午餐團購 - 池上便當",
                store: Store.sampleStores[2],
                organizer: userLeo, // Leo 是建立者
                endTime: Date().addingTimeInterval(1800), // 30分鐘後
                notes: "請在備註欄註明要不要辣椒和泡菜",
                participants: [
                    Participant(
                        user: userLeo, 
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
                status: .active,
                createdAt: Date().addingTimeInterval(-300)
            ),
            GroupBuyOrder(
                title: "☕️ 咖啡提神 - 星巴克",
                store: Store.sampleStores[0],
                organizer: userLeo, // Leo 也是這個的建立者
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
                ], // Leo 建立但未參加
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
