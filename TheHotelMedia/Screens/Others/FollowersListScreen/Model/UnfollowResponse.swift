//
//  UnfollowResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


struct UnfollowResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
