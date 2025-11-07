//
//  RequestMobileOTPResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import Foundation


struct RequestMobileOTPResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
