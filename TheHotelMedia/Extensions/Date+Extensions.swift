//
//  Date+Extensions.swift
//  TheHotelMedia
//
//  Created by MAC on 27/12/25.
//

import Foundation

extension Date {
    static func isWithinGracePeriod(dateString: String?) -> Bool {
        print("🔍 Checking Grace Period for date: \(String(describing: dateString))")
        guard let dateString = dateString, !dateString.isEmpty else {
            print("❌ Date string is nil or empty")
            return false
        }
        
        let dateFormatter = ISO8601DateFormatter()
        // Improve compatibility with fractional seconds if needed
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = dateFormatter.date(from: dateString)
        
        // Fallback for standard ISO8601 without fractional seconds
        if date == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            date = dateFormatter.date(from: dateString)
        }
        
        // Fallback for SQL format (often used in backends) "yyyy-MM-dd HH:mm:ss"
        if date == nil {
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
            date = simpleFormatter.date(from: dateString)
        }
        
        guard let profileCreatedDate = date else {
            print("❌ Failed to parse date: \(dateString)")
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if let monthsAgo = calendar.dateComponents([.month], from: profileCreatedDate, to: now).month {
            print("✅ Account age in months: \(monthsAgo)")
            return monthsAgo < 11
        }
        
        return false
    }
}
