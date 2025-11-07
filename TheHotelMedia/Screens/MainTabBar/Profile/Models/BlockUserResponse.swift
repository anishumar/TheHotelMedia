//
//  BlockUserResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 04/11/24.
//

import Foundation


struct BlockUserResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
