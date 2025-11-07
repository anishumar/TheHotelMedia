//
//  GetUserVideosResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 14/10/24.
//

import Foundation


struct GetUserVideosResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [MediaRef]?
    let pageNo, totalPages, totalResources: Int?
}
