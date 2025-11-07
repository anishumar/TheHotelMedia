//
//  LikeStoryResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//

import Foundation

struct LikeStoryResponse: Codable, Refreshable {
    let message: String
    let status: Bool
    let statusCode: Int
}
