//
//  ReportProfileResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 29/11/24.
//

import Foundation


struct ReportProfileResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
