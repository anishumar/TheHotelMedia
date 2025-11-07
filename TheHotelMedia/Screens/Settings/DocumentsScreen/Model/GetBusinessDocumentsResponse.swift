//
//  GetBusinessDocumentsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 06/12/24.
//

import Foundation

// MARK: - Welcome
struct GetBusinessDocumentsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [DocumentData]?
}

// MARK: - Datum
struct DocumentData: Codable {
    let id, businessProfileID: String?
    let businessRegistration, addressProof: String?
    let createdAt, updatedAt: String?
    let v: Int?
}
