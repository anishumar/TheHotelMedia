//
//  SearchPostDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 16/10/24.
//

import Foundation


struct SearchPostDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [PostData]?
    let pageNo, totalPages, totalResources: Int?
}
