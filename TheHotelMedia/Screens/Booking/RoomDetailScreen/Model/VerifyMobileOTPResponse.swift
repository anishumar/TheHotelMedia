//
//  VerifyMobileOTPResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import Foundation


struct VerifyMobileOTPResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: MobileOTPVerifyData?
}


struct MobileOTPVerifyData: Codable {
    let errors, message, name: String?
}
