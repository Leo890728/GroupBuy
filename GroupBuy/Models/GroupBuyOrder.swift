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
    var organizer: String
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

struct Participant: Identifiable, Codable {
    let id = UUID()
    var name: String
    var order: String
    var price: Double
    var notes: String
    var joinedAt: Date
}
