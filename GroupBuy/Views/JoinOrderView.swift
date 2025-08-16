//
//  JoinOrderView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct JoinOrderView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.getActiveOrders().isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("目前沒有進行中的團購")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("快去發起一個團購吧！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.getActiveOrders()) { order in
                            NavigationLink(destination: JoinOrderDetailView(order: order, viewModel: viewModel)) {
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

struct OrderCardView: View {
    let order: GroupBuyOrder
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(order.title)
                        .font(.headline)
                    
                    Label(order.store.name, systemImage: order.store.imageURL)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(order.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())
                    
                    Text("\(order.participants.count) 人參與")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("發起人", systemImage: "person.fill")
                    .font(.caption)
                Text(order.organizer)
                    .font(.caption)
                
                Spacer()
                
                Label("結束時間", systemImage: "clock.fill")
                    .font(.caption)
                Text(order.endTime, style: .time)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            if !order.notes.isEmpty {
                Text(order.notes)
                    .font(.caption)
                    .padding(.top, 4)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 移除按鈕，因為會用 NavigationLink 包裹
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch order.status {
        case .active:
            return .green
        case .closed:
            return .orange
        case .completed:
            return .gray
        }
    }
}

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
    
    return JoinOrderView(viewModel: viewModel)
}
