//
//  Constants.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import Foundation
import SwiftUI

// MARK: - App Constants
enum AppConstants {
    
    // MARK: - UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 5
        static let standardPadding: CGFloat = 16
        static let cardPadding: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let profileImageSize: CGFloat = 40
    }
    
    // MARK: - Animation Constants
    enum Animation {
        static let defaultDuration: TimeInterval = 0.3
        static let springResponse: Double = 0.6
        static let springDamping: Double = 0.8
        static let pulseInterval: TimeInterval = 1.0
    }
    
    // MARK: - Limits
    enum Limits {
        static let maxStorePhotos: Int = 5
        static let maxOrderNotes: Int = 200
        static let maxStoreName: Int = 50
        static let searchDebounceDelay: UInt64 = 500_000_000 // 0.5秒 in nanoseconds
    }
    
    // MARK: - Default Values
    enum Defaults {
        static let orderDurationHours: TimeInterval = 1 // 預設團購時長1小時
        static let searchRadius: Double = 5000 // 搜尋半徑5公里
    }
}

// MARK: - Color Constants
extension Color {
    static let primaryAccent = Color.blue
    static let secondaryAccent = Color.orange
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    
    // Status colors
    static let activeStatus = Color.green
    static let closedStatus = Color.orange
    static let completedStatus = Color.gray
}

// MARK: - SF Symbols Constants
enum SFSymbols {
    // Tab bar icons
    static let home = "house.fill"
    static let orders = "list.bullet"
    static let stores = "storefront.fill"
    
    // Common action icons
    static let add = "plus"
    static let search = "magnifyingglass"
    static let voice = "mic.fill"
    static let location = "location.fill"
    static let phone = "phone.fill"
    static let camera = "camera.fill"
    static let photo = "photo"
    
    // Navigation icons
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let up = "chevron.up"
    static let down = "chevron.down"
    
    // Status icons
    static let checkmark = "checkmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let pin = "pin.fill"
    
    // Store category fallback
    static let storeDefault = "storefront"
}
