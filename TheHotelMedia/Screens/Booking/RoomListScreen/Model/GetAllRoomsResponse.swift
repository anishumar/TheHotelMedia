//
//  GetAllRoomsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation

// MARK: - GetAllRoomsResponse
struct GetAllRoomsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [ListRoom]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - Datum
struct ListRoom: Codable, Identifiable {
    let id, bedType: String?
    let adults, children, maxOccupancy: Int?
    let availability: Bool?
    let amenities: [String]?
    let roomType, businessProfileID, title, description: String?
    let pricePerNight: Int?
    let currency, mealPlan, createdAt, updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bedType, adults, children, maxOccupancy, availability, amenities, roomType, businessProfileID, title, description, pricePerNight, currency, mealPlan, createdAt, updatedAt
    }
}
