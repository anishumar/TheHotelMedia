//
//  BookBanquetResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 02/04/25.
//

import Foundation



// MARK: - BookBanquetResponse
struct BookBanquetResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
