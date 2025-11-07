//
//  ViewStoryResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import Foundation


struct ViewStoryResponse: Codable, Refreshable {
    let message: String
    let status: Bool
    let statusCode: Int
}
