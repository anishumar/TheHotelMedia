//
//  ChatUser.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/24.
//

import Foundation


struct ChatUser: Codable, Identifiable {
    let id: String?
    let userID: String?
    let isOnline: Int?
    let name: String?
    let profilePic: ProfilePic?
    let username: String?
    
    // Map the JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isOnline
        case name
        case profilePic
        case username
        case userID
    }
}
