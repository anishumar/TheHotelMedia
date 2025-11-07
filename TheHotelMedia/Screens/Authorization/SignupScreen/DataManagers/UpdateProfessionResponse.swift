//
//  UpdateProfessionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 16/04/25.
//

import Foundation


struct UpdateProfessionResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
