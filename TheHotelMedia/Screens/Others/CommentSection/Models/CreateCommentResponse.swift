//
//  CreateCommentResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation

struct CreateCommentResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
struct DeleteCommentResponse: Codable, Refreshable {
    let status: Bool
    let message: String
    var statusCode: Int
    
    enum CodingKeys: String, CodingKey {
        case status, message
        // statusCode is not in API response, so we don't decode it
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Bool.self, forKey: .status)
        message = try container.decode(String.self, forKey: .message)
        statusCode = 200 // Default value since API doesn't return it
    }
}
