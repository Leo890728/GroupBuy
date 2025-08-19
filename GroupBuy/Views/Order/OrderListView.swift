//
//  OrderListView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

struct OrderListView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.activeOrders.isEmpty {
                    EmptyOrdersView()
                } else {
                    OrdersList(orders: viewModel.activeOrders)
                }
            }
            .navigationTitle("我的訂單")
        }
    }
}

// MARK: - Sub Components

private struct EmptyOrdersView: View {
    var body: some View {
        EmptyStateView.emptyOrders()
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

#Preview {
    OrderListView(viewModel: GroupBuyViewModel())
}
