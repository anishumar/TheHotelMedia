//
//  RecentChat.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/24.
//

import Foundation


struct RecentChat: Codable, Identifiable {
    let id: String?
    let createdAt: String?
    let isSeen: Int?
    let message: String?
    let name: String?
    let profilePic: ProfilePic?
    let type: String?
    let unseenCount: Int?
    let username: String?
}
