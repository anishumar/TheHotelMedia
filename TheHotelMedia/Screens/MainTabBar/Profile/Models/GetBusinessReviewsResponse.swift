//
//  GetBusinessReviewsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 15/10/24.
//

import Foundation


struct GetBusinessReviewsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [PostData]?
    let pageNo, totalPages, totalResources: Int?
}
