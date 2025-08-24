//
//  OrderComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// MARK: - Order Status Badge
/// 訂單狀態徽章組件
struct OrderStatusBadge: View {
    let status: GroupBuyOrder.OrderStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .closed:
            return .orange
        case .completed:
            return .gray
        }
    }
}

// MARK: - Order Row View
/// 訂單列表行組件，用於我的訂單列表
struct OrderRowView: View {
    let order: GroupBuyOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.title)
                    .font(.headline)
                Spacer()
                OrderStatusBadge(status: order.status)
            }
            
            Text(order.store.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("發起人: \(order.organizer.name)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Order Summary Card
/// 訂單統計卡片組件
struct OrderSummaryCard: View {
    let orderCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cart.badge.plus")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("進行中的團購")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(orderCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            if orderCount > 0 {
                Text("點擊訂單查看詳情並參加團購")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Order Card View
/// 訂單卡片組件，用於參加團購的卡片顯示
struct OrderCardView: View {
    let order: GroupBuyOrder
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(order.title)
                        .font(.headline)
                    
                    HStack {
                        // 修復圖片顯示問題：使用 AsyncImage 替代 Label with systemName
                        if let url = URL(string: order.store.imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                @unknown default:
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(order.store.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    OrderStatusBadge(status: order.status)
                    
                    Text("\(order.participants.count) 人參與")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("發起人", systemImage: "person.fill")
                    .font(.caption)
                Text(order.organizer.name)
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Order Info Section
/// 訂單詳細資訊區塊組件
struct OrderInfoSection: View {
    let order: GroupBuyOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                OrderStatusBadge(status: order.status)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "storefront.fill", title: "商店", content: order.store.name)
                InfoRow(icon: "person.fill", title: "發起人", content: order.organizer.name)
                InfoRow(icon: "clock.fill", title: "結束時間", content: order.endTime.formatted(date: .abbreviated, time: .shortened))
                InfoRow(icon: "person.2.fill", title: "參與人數", content: "\(order.participants.count) 人")
                
                if !order.notes.isEmpty {
                    InfoRow(icon: "note.text", title: "備註", content: order.notes)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
/// 資訊行組件，顯示圖示、標題和內容
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(content)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Previews
#Preview("Order Status Badge") {
    VStack(spacing: 8) {
        OrderStatusBadge(status: .active)
        OrderStatusBadge(status: .closed)
        OrderStatusBadge(status: .completed)
    }
}

#Preview("Order Row") {
    OrderRowView(order: GroupBuyOrder(
        title: "午餐團購",
        store: Store.sampleStores[0],
        organizer: User(name: "小明", email: "ming@example.com"),
        endTime: Date().addingTimeInterval(3600),
        notes: "請準時取餐",
        participants: [],
        status: .active,
        createdAt: Date()
    ))
}

#Preview("Order Card") {
    OrderCardView(order: GroupBuyOrder(
        title: "下午茶團購",
        store: Store.sampleStores[0],
        organizer: User(name: "小華", email: "hua@example.com"),
        endTime: Date().addingTimeInterval(7200),
        notes: "請在備註欄填寫甜度和冰塊需求",
        participants: [],
        status: .active,
        createdAt: Date()
    )) {
        print("Join order tapped")
    }
}
