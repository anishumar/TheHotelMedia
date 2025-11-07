//
//  CreateEventResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 09/10/24.
//

import Foundation



struct CreateEventResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
