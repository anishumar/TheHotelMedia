//
//  CancelSubscriptionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 18/11/24.
//

import Foundation


struct CancelSubscriptionResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
