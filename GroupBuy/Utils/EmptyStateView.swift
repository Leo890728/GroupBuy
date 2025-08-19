//
//  EmptyStateView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

/// 通用的空狀態視圖元件
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: EmptyStateAction?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: EmptyStateAction? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let action = action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

struct EmptyStateAction {
    let title: String
    let handler: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.handler = action
    }
}

// MARK: - Convenience Extensions

extension EmptyStateView {
    /// 訂單列表的空狀態
    static func emptyOrders(onCreateOrder: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: "還沒有訂單",
            subtitle: "發起您的第一個團購訂單",
            action: onCreateOrder.map { EmptyStateAction("發起團購", action: $0) }
        )
    }
    
    /// 商店搜尋的空狀態
    static func noSearchResults(searchText: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "找不到符合條件的商店",
            subtitle: "試試其他搜尋關鍵字"
        )
    }
    
    /// 商店列表的空狀態
    static func emptyStores(onAddStore: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "storefront",
            title: "還沒有商店",
            subtitle: "新增您喜愛的商店開始使用",
            action: onAddStore != nil ? EmptyStateAction("新增商店", action: onAddStore!) : nil
        )
    }
    
    /// 沒有可參加的團購
    static func noActiveOrders(onCreateOrder: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "cart.badge.questionmark",
            title: "目前沒有進行中的團購",
            subtitle: "快去發起一個團購吧！",
            action: onCreateOrder != nil ? EmptyStateAction("發起團購", action: onCreateOrder!) : nil
        )
    }
}

#Preview {
    Group {
        EmptyStateView.emptyOrders()
            .previewDisplayName("Empty Orders")
        
        EmptyStateView.noSearchResults(searchText: "測試")
            .previewDisplayName("No Search Results")
        
        EmptyStateView.emptyStores()
            .previewDisplayName("Empty Stores")
    }
}
