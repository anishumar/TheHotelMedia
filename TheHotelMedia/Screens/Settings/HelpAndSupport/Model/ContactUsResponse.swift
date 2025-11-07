//
//  ContactUsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 28/10/24.
//

import Foundation


struct ContactUsResponse: Codable, Refreshable {
    
    let status: Bool
    let statusCode: Int
    let message: String
}
