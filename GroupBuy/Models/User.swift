//
//  User.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/23.
//

import Foundation

struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var phone: String?
    var avatar: String? // 頭像圖片名稱或 URL
    var createdAt: Date
    var preferences: UserPreferences
    
    init(name: String, email: String, phone: String? = nil, avatar: String? = nil) {
        self.name = name
        self.email = email
        self.phone = phone
        self.avatar = avatar
        self.createdAt = Date()
        self.preferences = UserPreferences()
    }
}

struct UserPreferences: Codable {
    var enableNotifications: Bool = true
    var defaultDeliveryLocation: String = ""
    var favoriteStores: [UUID] = [] // 收藏的商店 ID
    var notificationBeforeEndTime: TimeInterval = 900 // 結束前 15 分鐘提醒
    
    init() {}
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        name: "Leo",
        email: "user@example.com",
        phone: "0912-345-678"
    )
    
    static let sampleUsers: [User] = [
        User(name: "小明", email: "ming@example.com", phone: "0987-654-321"),
        User(name: "小華", email: "hua@example.com"),
        User(name: "小美", email: "mei@example.com"),
        User(name: "小王", email: "wang@example.com")
    ]
}
