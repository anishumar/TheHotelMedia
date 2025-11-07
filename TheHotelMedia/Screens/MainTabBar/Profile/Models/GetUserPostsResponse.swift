//
//  GetUserPostsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 12/10/24.
//

import Foundation


struct GetUserPostsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [PostData]?
    let pageNo, totalPages, totalResources: Int?
}
