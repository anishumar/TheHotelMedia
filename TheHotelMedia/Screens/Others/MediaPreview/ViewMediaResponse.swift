//
//  ViewMediaResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import Foundation


struct ViewMediaResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
