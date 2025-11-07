//
//  GetNotificationResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


// MARK: - GetNotificationResponse
struct GetNotificationResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [NotificationModel]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - NotificationModel
struct NotificationModel: Codable, Identifiable, Hashable {
    let id: String?
    let isSeen: Bool?
    let userID: String?
    let title: String?
    let description: String?
    let type: String?
    let metadata: Metadata?
    let createdAt: String?
    let usersRef: UsersRef?
    let isConnected, isRequested: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isSeen, userID, title, description, type, metadata, createdAt, usersRef, isConnected, isRequested
    }
}

// MARK: - Metadata
struct Metadata: Codable, Hashable {
    let connectionID, userID, postID, message, postType, jobID, type, bookingID: String?
    let commentID: String?
}


// MARK: - UsersRef
struct UsersRef: Codable, Hashable {
    let id: String?
    let accountType: String?
    let profilePic: ProfilePic?
    let username, name, phoneNumber, dialCode, email: String?
    let businessProfileRef: BusinessProfileRef?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, profilePic, username, name, businessProfileRef, dialCode, phoneNumber, email
    }
}
