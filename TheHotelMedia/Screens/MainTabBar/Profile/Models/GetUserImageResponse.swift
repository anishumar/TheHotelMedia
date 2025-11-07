//
//  GetUserImageResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 12/10/24.
//

import Foundation


struct GetUserImageResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [MediaRef]?
    let pageNo, totalPages, totalResources: Int?
}
