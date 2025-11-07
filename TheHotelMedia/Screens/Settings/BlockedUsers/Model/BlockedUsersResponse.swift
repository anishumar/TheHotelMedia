//
//  BlockedUsersResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 08/11/24.
//

import Foundation


struct BlockedUsersResponse: Codable, Refreshable {
    let message: String
    let status: Bool
    let statusCode: Int
    let data: [SearchProfileData]?
    let pageNo, totalPages, totalResources: Int?
}
