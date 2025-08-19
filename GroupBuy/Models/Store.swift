//
//  Store.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import Foundation
import PhotosUI
import MapKit
import SwiftUI

// 可編碼的 MKPointOfInterestCategory 包裝器
struct CodableMKPointOfInterestCategory: Codable {
    let category: MKPointOfInterestCategory?
    
    init(_ category: MKPointOfInterestCategory?) {
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawValue = try? container.decode(String.self) {
            self.category = MKPointOfInterestCategory(rawValue: rawValue)
        } else {
            self.category = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(category?.rawValue)
    }
}

struct Store: Identifiable, Codable {
    var id = UUID()
    var name: String
    var address: String
    var phoneNumber: String
    var photos: [URL]?
    var imageURL: String
    private var _category: CodableMKPointOfInterestCategory
    var description: String
    var isCustom: Bool = false
    
    var category: MKPointOfInterestCategory? {
        get { _category.category }
        set { _category = CodableMKPointOfInterestCategory(newValue) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, phoneNumber, photos, imageURL, description, isCustom
        case _category = "category"
    }
    
    init(id: UUID = UUID(), name: String, address: String, phoneNumber: String, photos: [URL]? = nil, imageURL: String, category: MKPointOfInterestCategory? = nil, description: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.address = address
        self.phoneNumber = phoneNumber
        self.photos = photos
        self.imageURL = imageURL
        self._category = CodableMKPointOfInterestCategory(category)
        self.description = description
        self.isCustom = isCustom
    }
    
    // 實例方法：獲取圖示
    var spotlightIcon: String {
        return Store.spotlightIcon(for: category)
    }
    
    // 實例方法：獲取顏色
    var spotlightColor: Color {
        return Store.spotlightColor(for: category)
    }
    
    // 實例方法：獲取分類顯示名稱
    var categoryDisplayName: String {
        return Store.categoryDisplayName(for: category)
    }
}

// 常用的興趣點分類
extension Store {
    static let commonCategories: [MKPointOfInterestCategory] = [
        .cafe,
        .restaurant,
        .bakery,
        .store,
        .foodMarket
    ]
    
    // 取得分類的中文顯示名稱
    static func categoryDisplayName(for category: MKPointOfInterestCategory?) -> String {
        guard let category = category else { return "自訂" }
        
        switch category {
        case .cafe:
            return "飲料/咖啡"
        case .restaurant:
            return "餐廳"
        case .bakery:
            return "烘焙"
        case .store:
            return "商店"
        case .foodMarket:
            return "市場"
        default:
            return "其他"
        }
    }
    
    // 根據地點類型返回 Spotlight 風格圖示
    static func spotlightIcon(for category: MKPointOfInterestCategory?) -> String {
        guard let category = category else {
            return "location"
        }
        
        switch category {
        case .restaurant:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer"
        case .bakery, .foodMarket:
            return "basket"
        case .hospital:
            return "cross"
        case .pharmacy:
            return "cross.case"
        case .gasStation:
            return "fuelpump"
        case .hotel:
            return "bed.double"
        case .store:
            return "bag"
        case .school:
            return "building"
        case .university:
            return "graduationcap"
        case .library:
            return "books.vertical"
        case .museum:
            return "building.columns"
        case .movieTheater:
            return "tv"
        case .nightlife:
            return "music.note"
        case .park:
            return "leaf"
        case .publicTransport:
            return "bus"
        case .parking:
            return "car"
        case .bank:
            return "building.columns"
        case .atm:
            return "creditcard"
        case .postOffice:
            return "envelope"
        case .fireStation:
            return "flame"
        case .police:
            return "shield"
        case .beach:
            return "sun.max"
        case .campground:
            return "tent"
        case .fitnessCenter:
            return "figure.run"
        default:
            return "location"
        }
    }
    
    // 根據地點類型返回 Spotlight 風格顏色
    static func spotlightColor(for category: MKPointOfInterestCategory?) -> Color {
        guard let category = category else {
            return Color(.systemBlue)
        }
        
        switch category {
        case .restaurant, .cafe, .bakery, .foodMarket:
            return Color(.systemOrange)
        case .hospital, .pharmacy:
            return Color(.systemRed)
        case .gasStation:
            return Color(.systemBlue)
        case .hotel:
            return Color(.systemPurple)
        case .store:
            return Color(.systemGreen)
        case .school, .university, .library:
            return Color(.systemIndigo)
        case .museum:
            return Color(.systemBrown)
        case .movieTheater, .nightlife:
            return Color(.systemPink)
        case .park, .beach, .campground:
            return Color(.systemGreen)
        case .publicTransport, .parking:
            return Color(.systemBlue)
        case .bank, .atm:
            return Color(.systemGreen)
        case .postOffice:
            return Color(.systemBlue)
        case .fireStation:
            return Color(.systemRed)
        case .police:
            return Color(.systemBlue)
        case .fitnessCenter:
            return Color(.systemOrange)
        default:
            return Color(.systemBlue)
        }
    }
}

// 預設商店資料
extension Store {
    static let sampleStores = [
        Store(name: "清心福全", address: "台北市信義區", phoneNumber: "02-1234-5678", imageURL: "cup.and.saucer.fill", category: .cafe, description: "各式茶飲、果汁"),
        Store(name: "50嵐", address: "台北市大安區", phoneNumber: "02-2345-6789", imageURL: "cup.and.saucer.fill", category: .cafe, description: "手搖飲料專賣店"),
        Store(name: "池上便當", address: "台北市中正區", phoneNumber: "02-3456-7890", imageURL: "takeoutbag.and.cup.and.straw.fill", category: .restaurant, description: "傳統台式便當"),
        Store(name: "三商巧福", address: "台北市南港區", phoneNumber: "02-4567-8901", imageURL: "takeoutbag.and.cup.and.straw.fill", category: .restaurant, description: "牛肉麵、便當"),
        Store(name: "85度C", address: "台北市士林區", phoneNumber: "02-5678-9012", imageURL: "birthday.cake.fill", category: .bakery, description: "咖啡、蛋糕、麵包")
    ]
}
