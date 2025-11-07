//
//  TransactionValidateResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 17/02/25.
//

import Foundation


struct TransactionValidateResponse: Codable, Refreshable {
    var message: String
    var status: Bool
    var statusCode: Int
}
