//
//  Store.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import Foundation

struct Store: Identifiable, Codable {
    let id = UUID()
    var name: String
    var address: String
    var phoneNumber: String
    var photos: [String]?
    var imageURL: String
    var category: StoreCategory
    var description: String
    var isCustom: Bool = false
    
    enum StoreCategory: String, CaseIterable, Codable {
        case drinks = "飲料"
        case lunch = "便當"
        case dessert = "甜點"
        case snack = "點心"
        case custom = "自訂"
    }
}

// 預設商店資料
extension Store {
    static let sampleStores = [
        Store(name: "清心福全", address: "台北市信義區", phoneNumber: "02-1234-5678", imageURL: "cup.and.saucer.fill", category: .drinks, description: "各式茶飲、果汁"),
        Store(name: "50嵐", address: "台北市大安區", phoneNumber: "02-2345-6789", imageURL: "cup.and.saucer.fill", category: .drinks, description: "手搖飲料專賣店"),
        Store(name: "池上便當", address: "台北市中正區", phoneNumber: "02-3456-7890", imageURL: "takeoutbag.and.cup.and.straw.fill", category: .lunch, description: "傳統台式便當"),
        Store(name: "三商巧福", address: "台北市南港區", phoneNumber: "02-4567-8901", imageURL: "takeoutbag.and.cup.and.straw.fill", category: .lunch, description: "牛肉麵、便當"),
        Store(name: "85度C", address: "台北市士林區", phoneNumber: "02-5678-9012", imageURL: "birthday.cake.fill", category: .dessert, description: "咖啡、蛋糕、麵包")
    ]
}
