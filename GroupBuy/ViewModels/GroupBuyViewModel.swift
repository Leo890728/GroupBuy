//
//  GroupBuyViewModel.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import Foundation
import SwiftUI

class GroupBuyViewModel: ObservableObject {
    @Published var stores: [Store] = Store.sampleStores
    @Published var activeOrders: [GroupBuyOrder] = []
    @Published var userOrders: [GroupBuyOrder] = []
    
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
            activeOrders[index].participants.append(participant)
        }
    }
    
    func getActiveOrders() -> [GroupBuyOrder] {
        return activeOrders.filter { $0.status == .active && $0.endTime > Date() }
    }
    
    private func loadSampleData() {
        // 添加一些示例團購訂單
        let sampleOrder1 = GroupBuyOrder(
            title: "午餐團購 - 池上便當",
            store: stores[2], // 池上便當
            organizer: "小明",
            endTime: Date().addingTimeInterval(3600), // 1小時後
            notes: "請在備註欄註明要不要辣椒和泡菜",
            participants: [
                Participant(name: "小華", order: "排骨便當", price: 85, notes: "要辣椒", joinedAt: Date().addingTimeInterval(-300)),
                Participant(name: "小美", order: "雞腿便當", price: 90, notes: "不要泡菜", joinedAt: Date().addingTimeInterval(-200))
            ],
            status: .active,
            createdAt: Date().addingTimeInterval(-600)
        )
        
        let sampleOrder2 = GroupBuyOrder(
            title: "下午茶時間 - 50嵐",
            store: stores[1], // 50嵐
            organizer: "小王",
            endTime: Date().addingTimeInterval(1800), // 30分鐘後
            notes: "甜度冰塊請在備註欄說明",
            participants: [],
            status: .active,
            createdAt: Date().addingTimeInterval(-300)
        )
        
        activeOrders = [sampleOrder1, sampleOrder2]
    }
}
