//
//  JoinOrderListComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/24.
//

import SwiftUI

// MARK: - Search and Filter Section
struct SearchAndFilterSection: View {
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
struct FilterOptionsView: View {
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
struct FilterButton: View {
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

// MARK: - Refresh Button
struct RefreshButton: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await onRefresh()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
        }
        .disabled(isRefreshing)
        .animation(.easeInOut(duration: 1.0).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
    }
}

// MARK: - Main Content View
struct MainContentView: View {
    let orders: [GroupBuyOrder]
    let searchText: String
    let viewModel: GroupBuyViewModel
    @Binding var isRefreshing: Bool
    let dismiss: DismissAction
    @Binding var selectedOrder: GroupBuyOrder?
    
    var body: some View {
        Group {
            if orders.isEmpty {
                EmptyContentView(searchText: searchText, dismiss: dismiss)
            } else {
                OrderListContent(
                    orders: orders,
                    viewModel: viewModel,
                    isRefreshing: $isRefreshing,
                    selectedOrder: $selectedOrder
                )
            }
        }
    }
}

// MARK: - Empty Content View
struct EmptyContentView: View {
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

// MARK: - Order List Content
struct OrderListContent: View {
    let orders: [GroupBuyOrder]
    let viewModel: GroupBuyViewModel
    @Binding var isRefreshing: Bool
    @Binding var selectedOrder: GroupBuyOrder?
    
    var body: some View {
        List {
            // 訂單統計資訊
            OrderSummaryCard(orderCount: orders.count)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            // 訂單列表
            OrderListSection(orders: orders, viewModel: viewModel, selectedOrder: $selectedOrder)
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
        
        // 模擬網路請求延遲
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - Order List Section
struct OrderListSection: View {
    let orders: [GroupBuyOrder]
    let viewModel: GroupBuyViewModel
    @Binding var selectedOrder: GroupBuyOrder?
    
    var body: some View {
        ForEach(orders) { order in
            Button {
                selectedOrder = order
            } label: {
                EnhancedOrderCardView(order: order, viewModel: viewModel)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

#Preview("FilterOptionsView") {
    FilterOptionsView(selectedFilter: .constant(.all))
}

#Preview("SearchAndFilterSection") {
    SearchAndFilterSection(
        searchText: .constant(""),
        selectedFilter: .constant(.all),
        speechManager: SpeechRecognitionManager()
    )
}
