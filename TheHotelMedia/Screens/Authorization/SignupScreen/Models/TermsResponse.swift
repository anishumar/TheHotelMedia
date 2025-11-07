//
//  TermsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import Foundation


struct TermsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
