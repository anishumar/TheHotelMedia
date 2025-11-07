//
//  AcceptFollowResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


struct AcceptFollowResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
