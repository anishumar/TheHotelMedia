//
//  DeletePostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 01/01/25.
//

import Foundation


struct DeletePostResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
