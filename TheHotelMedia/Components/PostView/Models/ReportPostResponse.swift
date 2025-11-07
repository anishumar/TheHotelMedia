//
//  ReportPostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 25/11/24.
//

import Foundation


struct ReportPostResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
