//
//  CreatePostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 04/10/24.
//

import Foundation


struct CreatePostResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: CreatePostData?
    let postID: String? // Some APIs return postID at root level
    
    enum CodingKeys: String, CodingKey {
        case status, statusCode, message, data
        case postID = "_id" // Try _id at root level as well
    }
}

struct CreatePostData: Codable {
    let postID: String?
    
    enum CodingKeys: String, CodingKey {
        case postID = "_id"
    }
}
