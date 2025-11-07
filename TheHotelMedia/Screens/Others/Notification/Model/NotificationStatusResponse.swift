//
//  NotificationStatusResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 01/01/25.
//

import Foundation


struct NotificationStatusResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    let data: NotificationCategory?
}

// MARK: - NotificationCategory
struct NotificationCategory: Codable {
    let notifications, messages: Messages?
}

// MARK: - Messages
struct Messages: Codable {
    let hasUnreadMessages: Bool?
    let count: Int?
}
