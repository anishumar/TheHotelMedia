//
//  ConfirmBookingResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 24/02/25.
//

import Foundation


struct ConfirmBookingResponse: Codable, Refreshable {
    let message: String
    let status: Bool
    let statusCode: Int
}
