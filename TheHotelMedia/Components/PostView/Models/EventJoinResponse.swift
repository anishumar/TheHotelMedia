//
//  EventJoinResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/11/24.
//

import Foundation


struct EventJoinResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
