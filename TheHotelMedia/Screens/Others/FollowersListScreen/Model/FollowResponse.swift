//
//  FollowResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


// MARK: - Welcome
struct FollowResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: FollowResponseData?
}

// MARK: - DataClass
struct FollowResponseData: Codable {
    let status, id, follower, following: String?
    let createdAt, updatedAt: String?
    let v: Int?
    let dataID: String?

    enum CodingKeys: String, CodingKey {
        case status
        case id = "_id"
        case follower, following, createdAt, updatedAt
        case v = "__v"
        case dataID = "id"
    }
}
