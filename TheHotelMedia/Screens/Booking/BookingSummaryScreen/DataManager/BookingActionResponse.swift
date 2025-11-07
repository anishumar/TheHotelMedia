//
//  BookingActionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 14/05/25.
//

import Foundation


struct BookingActionResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
