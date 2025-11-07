//
//  CommentsDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation



struct CommentsDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [Comment]?
    let pageNo: Int?
    let totalPages: Int?
    let totalResources: Int?
}

struct Comment: Codable, Identifiable, Equatable {
    let id: String?
    let isParent: Bool?
    let userID, businessProfileID, postID, message: String?
    let createdAt: String?
    let repliesRef: [ReplyComment]?
    let commentedBy: CommentedBy?
    let likes: Int?
    let likedByMe: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isParent, userID, businessProfileID, postID, message, createdAt, commentedBy, likes, likedByMe, repliesRef
    }
}

// MARK: - CommentedBy
struct CommentedBy: Codable, Equatable {
    let id, accountType, businessProfileID, name: String?
    let businessProfileRef: BusinessProfileRef?
    let profilePic: ProfilePic?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, businessProfileID, name, businessProfileRef, profilePic
    }
}


struct ReplyComment: Codable, Identifiable, Equatable {
    let likes: Int?
    let isParent: Bool?
    let businessProfileID, postID, parentID, createdAt: String?
    let userID: String?
    let likedByMe: Bool?
    let commentedBy: CommentedBy?
    let id, message: String?

    enum CodingKeys: String, CodingKey {
        case likes, isParent, businessProfileID, postID, parentID, createdAt, userID, likedByMe, commentedBy
        case id = "_id"
        case message
    }
}

