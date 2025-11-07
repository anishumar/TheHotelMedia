//
//  DeleteCommentResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/11/25.
//

import Foundation


// struct DeleteCommentResponse: Codable, Refreshable {
//     let status: Bool
//     let message: String
//     var statusCode: Int
    
//     enum CodingKeys: String, CodingKey {
//         case status, message
//         // statusCode is not in API response, so we don't decode it
//     }
    
//     init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         status = try container.decode(Bool.self, forKey: .status)
//         message = try container.decode(String.self, forKey: .message)
//         statusCode = 200 // Default value since API doesn't return it
//     }
// }

