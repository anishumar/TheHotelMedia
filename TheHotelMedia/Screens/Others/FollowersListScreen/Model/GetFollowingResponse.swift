//
//  GetFollowingResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import Foundation


struct GetFollowingResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SearchProfileData]?
    let pageNo, totalPages, totalResources: Int?
}
