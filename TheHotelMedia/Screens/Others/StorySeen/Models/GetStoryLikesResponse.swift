//
//  GetStoryLikesResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//

import Foundation


struct GetStoryLikesResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SearchProfileData]?
    let pageNo, totalPages, totalResources: Int?
}
