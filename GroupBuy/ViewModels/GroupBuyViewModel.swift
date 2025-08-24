//
//  GroupBuyViewModel.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import Foundation
import SwiftUI

// MARK: - Filter Options
enum FilterOption: String, CaseIterable {
    case all = "全部"
    case endingSoon = "即將結束"
    case fewParticipants = "參與人數少"
    
    var icon: String {
        switch self {
        case .all:
            return "list.bullet"
        case .endingSoon:
            return "clock.fill"
        case .fewParticipants:
            return "person.2.fill"
        }
    }
}

class GroupBuyViewModel: ObservableObject {
    @Published var stores: [Store] = Store.sampleStores
    @Published var activeOrders: [GroupBuyOrder] = []
    @Published var userOrders: [GroupBuyOrder] = []
    
    // User Manager
    @Published var userManager = UserManager()
    
    // 當前正在編輯的訂單項目（可選，用於狀態管理）
    @Published var currentOrderItems: [OrderItem] = []
    @Published var currentParticipantNotes: String = ""
    
    init() {
        // 添加一些測試數據
        loadSampleData()
    }
    
    func addCustomStore(_ store: Store) {
        stores.append(store)
    }
    
    func updateStore(_ updatedStore: Store) {
        if let index = stores.firstIndex(where: { $0.id == updatedStore.id }) {
            stores[index] = updatedStore
        }
    }
    
    func removeStore(atOffsets offsets: IndexSet) {
        stores.remove(atOffsets: offsets)
    }
    
    func toggleStorePin(_ store: Store) {
        // 使用 withAnimation 確保狀態變更時有動畫
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if let index = stores.firstIndex(where: { $0.id == store.id }) {
                stores[index].isPinned.toggle()
            }
        }
    }
    
    func createGroupBuyOrder(_ order: GroupBuyOrder) {
        activeOrders.append(order)
    }
    
    func joinOrder(_ order: GroupBuyOrder, participant: Participant) {
        if let index = activeOrders.firstIndex(where: { $0.id == order.id }) {
            // if participant from same user exists, update it
            if let existingIndex = activeOrders[index].participants.firstIndex(where: { $0.user.id == participant.user.id }) {
                activeOrders[index].participants[existingIndex] = participant
            } else {
                activeOrders[index].participants.append(participant)
            }
        }
    }
    
    // MARK: - User Related Methods
    
    func createOrderAsCurrentUser(title: String, store: Store, endTime: Date, notes: String) {
        guard let currentUser = userManager.currentUser else { return }
        
        let newOrder = GroupBuyOrder(
            title: title,
            store: store,
            organizer: currentUser, // 直接使用 User 物件
            endTime: endTime,
            notes: notes,
            participants: [],
            status: .active,
            createdAt: Date()
        )
        
        createGroupBuyOrder(newOrder)
    }
    
    func joinOrderAsCurrentUser(_ order: GroupBuyOrder, orderDetails: String, price: Double, notes: String) {
        guard let currentUser = userManager.currentUser else { return }
        
        let participant = Participant(
            user: currentUser, // 直接使用 User 物件
            order: orderDetails,
            price: price,
            notes: notes,
            joinedAt: Date()
        )
        
        joinOrder(order, participant: participant)
    }
    
    // 新增：支援多商品的參加團購方法
    func joinOrderAsCurrentUserWithItems(_ order: GroupBuyOrder, items: [OrderItem], notes: String) {
        guard let currentUser = userManager.currentUser else { return }
        
        let participant = Participant(
            user: currentUser,
            items: items,
            notes: notes,
            joinedAt: Date()
        )
        
    joinOrder(order, participant: participant)
        
        // 參加成功後清理狀態
        clearCurrentOrderState()
    }
    
    // MARK: - 狀態管理方法
    
    /// 清理當前訂單編輯狀態
    func clearCurrentOrderState() {
        currentOrderItems.removeAll()
        currentParticipantNotes = ""
    }
    
    /// 設置當前訂單編輯狀態
    func setCurrentOrderState(items: [OrderItem], notes: String) {
        currentOrderItems = items
        currentParticipantNotes = notes
    }
    
    func getActiveOrders() -> [GroupBuyOrder] {
        return activeOrders.filter { $0.status == .active && $0.endTime > Date() }
    }
    
    // MARK: - 過濾和搜尋優化
    func getFilteredOrders(searchText: String, filter: FilterOption) -> [GroupBuyOrder] {
        let activeOrders = getActiveOrders()
        var filtered = activeOrders
        
        // 搜尋過濾 - 使用 lazy 來提高效能
        if !searchText.isEmpty {
            filtered = filtered.filter { order in
                order.title.localizedCaseInsensitiveContains(searchText) ||
                order.store.name.localizedCaseInsensitiveContains(searchText) ||
                order.organizer.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 分類過濾
        switch filter {
        case .all:
            break
        case .endingSoon:
            filtered = filtered.filter { $0.endTime.timeIntervalSinceNow < 3600 } // 1小時內結束
        case .fewParticipants:
            filtered = filtered.filter { $0.participants.count <= 2 }
        }
        
        // 按結束時間排序，即將結束的在前面
        return filtered.sorted { $0.endTime < $1.endTime }
    }
    
    // 取得使用者主持的團購訂單
    func getHostedOrders() -> [GroupBuyOrder] {
        guard let currentUser = userManager.currentUser else { return [] }
        return activeOrders.filter { $0.organizer.id == currentUser.id }
    }
    
    // 取得使用者參加的團購訂單
    func getJoinedOrders() -> [GroupBuyOrder] {
        guard let currentUser = userManager.currentUser else { return [] }
        return activeOrders.filter { order in
            order.participants.contains { $0.user.id == currentUser.id }
        }
    }
    
    private func loadSampleData() {
        // 添加一些示例團購訂單
        guard let currentUser = userManager.currentUser else { return }
        
        // 建立示例使用者
        let xiaHua = User(name: "小華", email: "hua@example.com")
        let xiaoMei = User(name: "小美", email: "mei@example.com")
        let xiaoWang = User(name: "小王", email: "wang@example.com")
        
        let sampleOrder1 = GroupBuyOrder(
            title: "午餐團購 - 池上便當",
            store: stores[2], // 池上便當
            organizer: currentUser, // 使用實際 User 物件
            endTime: Date().addingTimeInterval(3600), // 1小時後
            notes: "請在備註欄註明要不要辣椒和泡菜",
            participants: [
                Participant(
                    user: xiaHua,
                    items: [
                        OrderItem(name: "排骨便當", price: 85, notes: "要辣椒")
                    ],
                    notes: "要辣椒",
                    joinedAt: Date().addingTimeInterval(-300)
                ),
                Participant(
                    user: xiaoMei,
                    items: [
                        OrderItem(name: "雞腿便當", price: 90, notes: "不要泡菜"),
                        OrderItem(name: "冬瓜茶", price: 20, quantity: 2)
                    ],
                    notes: "分兩個袋子",
                    joinedAt: Date().addingTimeInterval(-200)
                )
            ],
            status: .active,
            createdAt: Date().addingTimeInterval(-600)
        )
        
        let sampleOrder2 = GroupBuyOrder(
            title: "下午茶時間 - 50嵐",
            store: stores[1], // 50嵐
            organizer: xiaoWang,
            endTime: Date().addingTimeInterval(1800), // 30分鐘後
            notes: "甜度冰塊請在備註欄說明",
            participants: [
                Participant(
                    user: currentUser,
                    items: [
                        OrderItem(name: "珍珠奶茶", price: 45, notes: "微糖少冰"),
                        OrderItem(name: "雞排", price: 55, quantity: 1)
                    ],
                    notes: "要分袋裝",
                    joinedAt: Date().addingTimeInterval(-100)
                )
            ],
            status: .active,
            createdAt: Date().addingTimeInterval(-300)
        )
        
        activeOrders = [sampleOrder1, sampleOrder2]
    }
}
