//
//  GroupBuyOrder.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import Foundation

struct GroupBuyOrder: Identifiable, Codable {
    let id = UUID()
    var title: String
    var store: Store
    var organizer: User // 改為 User 物件
    var endTime: Date
    var notes: String
    var participants: [Participant]
    var status: OrderStatus
    var createdAt: Date
    
    enum OrderStatus: String, CaseIterable, Codable {
        case active = "進行中"
        case closed = "已結束"
        case completed = "已完成"
    }
}

// MARK: - Order Item
struct OrderItem: Identifiable, Codable {
    let id = UUID()
    var name: String
    var price: Double
    var quantity: Int = 1
    var notes: String = ""
    
    var totalPrice: Double {
        return price * Double(quantity)
    }
}

struct Participant: Identifiable, Codable {
    let id = UUID()
    var user: User // 改為 User 物件
    var items: [OrderItem] // 改為多個商品項目
    var notes: String // 整體備註
    var joinedAt: Date
    
    // 保留 name 作為計算屬性
    var name: String {
        return user.name
    }
    
    // 計算總價
    var totalPrice: Double {
        return items.reduce(0) { $0 + $1.totalPrice }
    }
    
    // 為了向後相容性，保留舊的屬性作為計算屬性
    var order: String {
        return items.map { item in
            let quantity = item.quantity > 1 ? " x\(item.quantity)" : ""
            return item.name + quantity
        }.joined(separator: ", ")
    }
    
    var price: Double {
        return totalPrice
    }
    
    // 從舊格式建立的便利初始化器
    init(user: User, order: String, price: Double, notes: String, joinedAt: Date) {
        self.user = user
        self.items = [OrderItem(name: order, price: price, notes: notes)]
        self.notes = notes
        self.joinedAt = joinedAt
    }
    
    // 新的多商品初始化器
    init(user: User, items: [OrderItem], notes: String, joinedAt: Date) {
        self.user = user
        self.items = items
        self.notes = notes
        self.joinedAt = joinedAt
    }
}
