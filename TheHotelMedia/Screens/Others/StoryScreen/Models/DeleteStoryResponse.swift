//
//  DeleteStoryResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import Foundation


struct DeleteStoryResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
