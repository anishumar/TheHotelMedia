//
//  BusinessSignupResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import Foundation


struct BusinessSignupResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: LoginData?
    
}
