//
//  BillingAddressResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 19/11/24.
//

import Foundation


struct BillingAddressResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
