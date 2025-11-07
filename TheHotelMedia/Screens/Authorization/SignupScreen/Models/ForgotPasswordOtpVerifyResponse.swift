//
//  ForgotPasswordOtpVerifyResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


struct ForgotPasswordOtpVerifyResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: ForgotPassword?
}

struct ForgotPassword: Codable {
    var email: String?
    var resetToken: String?
}
