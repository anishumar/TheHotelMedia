//
//  ForgotPasswordResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


struct ForgotPasswordResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
