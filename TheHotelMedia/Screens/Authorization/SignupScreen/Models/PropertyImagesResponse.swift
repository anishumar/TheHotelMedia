//
//  PropertyImagesResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 12/10/24.
//

import Foundation



struct PropertyImagesResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
