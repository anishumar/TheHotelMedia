//
//  CommentLikeResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 11/10/24.
//

import Foundation


struct CommentLikeResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
