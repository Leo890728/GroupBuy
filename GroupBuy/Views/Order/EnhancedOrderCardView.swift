//
//  EnhancedOrderCardView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/24.
//

import SwiftUI

// MARK: - Enhanced Order Card View
struct EnhancedOrderCardView: View {
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
                Spacer()
                // 參與指示器
                ParticipationIndicator(order: order, viewModel: viewModel, userManager: viewModel.userManager)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

// MARK: - Order Header View
struct OrderHeaderView: View {
    let order: GroupBuyOrder
    
    private var timeInfo: (remaining: String, color: Color) {
        TimeHelper.formatTimeRemaining(from: order.endTime)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                StoreIconView(store: order.store)
                
                Text(order.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                TimeRemainingLabel(timeInfo: timeInfo)
            }
            
            HStack(spacing: 4) {
                Text(order.store.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                ParticipantCountLabel(count: order.participants.count)
            }
        }
    }
}

// MARK: - Order Info View
struct OrderInfoView: View {
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

// MARK: - Order Notes View
struct OrderNotesView: View {
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

// MARK: - Participation Indicator
struct ParticipationIndicator: View {
    let order: GroupBuyOrder
    let viewModel: GroupBuyViewModel
    @ObservedObject var userManager: UserManager
    
    private var isOrganizer: Bool {
        guard let currentUser = userManager.currentUser else { return false }
        return order.organizer.id == currentUser.id
    }
    
    private var isParticipating: Bool {
        userManager.isParticipatingInOrder(order)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if isParticipating {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text(isOrganizer ? "已參加 (建立者)" : "已參加")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            } else {
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

// MARK: - Time Remaining Label
struct TimeRemainingLabel: View {
    let timeInfo: (remaining: String, color: Color)
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundColor(timeInfo.color)
            
            Text(timeInfo.remaining)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(timeInfo.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(timeInfo.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Participant Count Label
struct ParticipantCountLabel: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count) 人")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Time Helper (移至獨立工具類)
enum TimeHelper {
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

#Preview("EnhancedOrderCardView") {
    EnhancedOrderCardView(
        order: GroupBuyOrder(
            title: "🍱 午餐團購 - 池上便當",
            store: Store.sampleStores[0],
            organizer: User.sampleUser,
            endTime: Date().addingTimeInterval(1800),
            notes: "請在備註欄註明要不要辣椒和泡菜",
            participants: [],
            isPublic: true,
            status: .active,
            createdAt: Date()
        ),
        viewModel: GroupBuyViewModel()
    )
    .padding()
}
