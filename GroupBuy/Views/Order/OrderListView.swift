//
//  OrderListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// 篩選範圍：我主辦的 / 我參加的
enum SelectionScope: String, CaseIterable, Identifiable {
    case hosted = "我主辦的"
    case joined = "我參加的"

    var id: String { rawValue }
}

struct OrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    // 可選的初始選擇範圍（hosted / joined）
    var initialSelectionScope: SelectionScope? = nil
    @State private var searchText = ""
    @StateObject private var speechManager = SpeechRecognitionManager()
    @State private var selectionScope: SelectionScope = .hosted
    
    // 根據搜尋文字過濾的我主辦的團購
    private var filteredHostedOrders: [GroupBuyOrder] {
        let hostedOrders = viewModel.getHostedOrders()
        if searchText.isEmpty {
            return hostedOrders
        }
        return hostedOrders.filter { order in
            order.title.localizedCaseInsensitiveContains(searchText) ||
            order.store.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // 根據搜尋文字過濾的我參加的團購
    private var filteredJoinedOrders: [GroupBuyOrder] {
        let joinedOrders = viewModel.getJoinedOrders()
        if searchText.isEmpty {
            return joinedOrders
        }
        return joinedOrders.filter { order in
            order.title.localizedCaseInsensitiveContains(searchText) ||
            order.store.name.localizedCaseInsensitiveContains(searchText) ||
            order.organizer.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋框
                SearchBarView(
                    searchText: $searchText,
                    speechManager: speechManager,
                    placeholder: "搜尋團購標題、商店或主辦人",
                    isSearching: false,
                    onSearchSubmit: {
                        // 搜尋提交邏輯
                    },
                    onSearchTextChange: { _ in
                        // 搜尋文字改變時的邏輯
                    }
                )
                .padding(.top, 8)

                // 篩選器：我主辦的 / 我參加的
                Picker("篩選", selection: $selectionScope) {
                    ForEach(SelectionScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 內容區域（根據 picker 篩選顯示）
                let showHosted = selectionScope == .hosted
                let showJoined = selectionScope == .joined

                // 當目前選擇的範圍沒有任何結果時顯示空狀態
                if (showHosted && filteredHostedOrders.isEmpty) || (showJoined && filteredJoinedOrders.isEmpty) {
                    if searchText.isEmpty {
                        EmptyOrdersView()
                    } else {
                        EmptySearchResultView(searchText: searchText)
                    }
                } else {
                    OrderSectionsList(
                        hostedOrders: filteredHostedOrders,
                        joinedOrders: filteredJoinedOrders,
                        viewModel: viewModel,
                        scope: selectionScope
                    )
                }
                
                Spacer()
            }
            .navigationTitle("我的團購")
        }
        .onReceive(speechManager.$recognizedText) { recognizedText in
            if !recognizedText.isEmpty {
                searchText = recognizedText
            }
        }
        .onAppear {
            if let initial = initialSelectionScope {
                selectionScope = initial
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetOrderListScope"))) { notification in
            if let obj = notification.object as? String {
                switch obj {
                case "hosted":
                    selectionScope = .hosted
                case "joined":
                    selectionScope = .joined
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Sub Components

private struct EmptyOrdersView: View {
    var body: some View {
        EmptyStateView.emptyOrders()
    }
}

private struct EmptySearchResultView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("找不到相關團購")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("搜尋「\(searchText)」沒有找到相關的團購訂單")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OrderSectionsList: View {
    let hostedOrders: [GroupBuyOrder]
    let joinedOrders: [GroupBuyOrder]
    let viewModel: GroupBuyViewModel
    let scope: SelectionScope
    @State private var editingOrder: GroupBuyOrder?

    var body: some View {
        List {
            // 根據 scope 決定是否顯示「我主辦的」分類
            if scope == .hosted {
                // 我主辦的 - 依狀態分類 (進行中 / 已結束 / 已完成)
                if !hostedOrders.isEmpty {
                    // Helper to filter by status
                    let active = hostedOrders.filter { $0.status == .active }
                    let closed = hostedOrders.filter { $0.status == .closed }
                    let completed = hostedOrders.filter { $0.status == .completed }

                    if !active.isEmpty {
                        Section {
                            ForEach(active) { order in
                                Button {
                                    editingOrder = order
                                } label: {
                                    HStack {
                                        OrderRowView(order: order)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            HStack {
                                Image(systemName: "person.badge.key")
                                    .foregroundColor(.blue)
                                Text("進行中")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(active.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if !closed.isEmpty {
                        Section {
                            ForEach(closed) { order in
                                Button {
                                    editingOrder = order
                                } label: {
                                    HStack {
                                        OrderRowView(order: order)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.orange)
                                Text("已結束")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(closed.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if !completed.isEmpty {
                        Section {
                            ForEach(completed) { order in
                                Button {
                                    editingOrder = order
                                } label: {
                                    HStack {
                                        OrderRowView(order: order)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            HStack {
                                Image(systemName: "checkmark.seal")
                                    .foregroundColor(.gray)
                                Text("已完成")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(completed.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // 我參加的section（scope 為 joined 時顯示）
            if scope == .joined {
                // 依狀態分類 (進行中 / 已結束 / 已完成)
                let activeJ = joinedOrders.filter { $0.status == .active }
                let closedJ = joinedOrders.filter { $0.status == .closed }
                let completedJ = joinedOrders.filter { $0.status == .completed }

                if !activeJ.isEmpty {
                    Section {
                        ForEach(activeJ) { order in
                            NavigationLink(destination: OrderDetailView(order: order, viewModel: viewModel)) {
                                OrderRowView(order: order)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.green)
                            Text("進行中")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(activeJ.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }

                if !closedJ.isEmpty {
                    Section {
                        ForEach(closedJ) { order in
                            NavigationLink(destination: OrderDetailView(order: order, viewModel: viewModel)) {
                                OrderRowView(order: order)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("已結束")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(closedJ.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }

                if !completedJ.isEmpty {
                    Section {
                        ForEach(completedJ) { order in
                            NavigationLink(destination: OrderDetailView(order: order, viewModel: viewModel)) {
                                OrderRowView(order: order)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "checkmark.seal")
                                .foregroundColor(.gray)
                            Text("已完成")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(completedJ.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .sheet(item: $editingOrder) { orderToEdit in
            EditOrderSheetWrapper(
                originalOrder: orderToEdit,
                editingOrder: $editingOrder,
                viewModel: viewModel
            )
            .presentationDetents([.height(600), .large])
        }
    }
}

private struct OrdersList: View {
    let orders: [GroupBuyOrder]
    
    var body: some View {
        List(orders) { order in
            OrderRowView(order: order)
        }
    }
}

// MARK: - OrderRowView 和 OrderStatusBadge 已移至 OrderComponents.swift

// MARK: - Supporting Components

// EditOrderSheet 的包裝器，用於處理狀態更新
private struct EditOrderSheetWrapper: View {
    let originalOrder: GroupBuyOrder
    @Binding var editingOrder: GroupBuyOrder?
    @State private var orderCopy: GroupBuyOrder
    let viewModel: GroupBuyViewModel
    
    init(originalOrder: GroupBuyOrder, editingOrder: Binding<GroupBuyOrder?>, viewModel: GroupBuyViewModel) {
        self.originalOrder = originalOrder
        self._editingOrder = editingOrder
        self._orderCopy = State(initialValue: originalOrder)
        self.viewModel = viewModel
    }
    
    var body: some View {
        EditOrderSheet(order: $orderCopy, onSave: { updated in
            // 更新到 viewModel
            viewModel.updateOrder(updated)
            // 關閉 sheet
            editingOrder = nil
        }, onCancel: { _ in
            // 由 viewModel 處理移除
            viewModel.removeOrder(originalOrder)
            editingOrder = nil
        })
        .onDisappear {
            editingOrder = nil
        }
    }
}

#Preview {
    OrderListView(viewModel: GroupBuyViewModel())
}
