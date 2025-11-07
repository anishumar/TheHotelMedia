//
//  PostLikedResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation


struct PostLikedResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
