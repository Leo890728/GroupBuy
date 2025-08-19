//
//  JoinOrderView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct JoinOrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.getActiveOrders().isEmpty {
                    EmptyStateView.noActiveOrders()
                } else {
                    List {
                        ForEach(viewModel.getActiveOrders()) { order in
                            NavigationLink(destination: OrderDetailView(order: order, viewModel: viewModel)) {
                                OrderCardView(order: order) {
                                    // 這裡不需要做任何事，因為 NavigationLink 會處理導航
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("參加團購")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                // 重新整理團購列表
            }
        }
    }
}

// MARK: - OrderCardView 已移至 OrderComponents.swift

#Preview {
    let viewModel = GroupBuyViewModel()
    // 添加一些測試數據
    viewModel.activeOrders = [
        GroupBuyOrder(
            title: "下午茶團購",
            store: Store.sampleStores[0],
            organizer: "小明",
            endTime: Date().addingTimeInterval(3600),
            notes: "請在備註欄填寫甜度和冰塊",
            participants: [],
            status: .active,
            createdAt: Date()
        )
    ]
    
    return JoinOrderListView(viewModel: viewModel)
}
