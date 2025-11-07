//
//  NewAccountResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import Foundation


struct NewAccountResponse: Codable {
    var status: Bool
    var statusCode: Int
    var message: String?
}
