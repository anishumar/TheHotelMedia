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
}
