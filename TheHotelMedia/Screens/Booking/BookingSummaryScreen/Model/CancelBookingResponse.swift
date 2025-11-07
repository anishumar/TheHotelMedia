//
//  CancelBookingResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 06/03/25.
//

import Foundation


struct CancelBookingResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
