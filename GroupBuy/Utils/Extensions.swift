//
//  Extensions.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import Foundation
import SwiftUI

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let displayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var displayString: String {
        if isToday {
            return "今天 \(DateFormatter.displayTime.string(from: self))"
        } else if isTomorrow {
            return "明天 \(DateFormatter.displayTime.string(from: self))"
        } else {
            return DateFormatter.shortDateTime.string(from: self)
        }
    }
}

// MARK: - Double Extensions
extension Double {
    var currencyString: String {
        return "NT$\(Int(self))"
    }
}

// MARK: - String Extensions  
extension String {
    var isValidPhoneNumber: Bool {
        let phoneRegex = "^09\\d{8}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}
