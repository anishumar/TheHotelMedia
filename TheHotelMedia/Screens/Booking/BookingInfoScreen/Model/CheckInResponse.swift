//
//  CheckInResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation

// MARK: - CheckInResponse
struct CheckInResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    var data: CheckInData?
}

// MARK: - DataClass
struct CheckInData: Codable {
    let booking: Booking?
    let roomsRequired: Int?
    let availableRooms: [AvailableRoom]?
    var user: User?
}

// MARK: - AvailableRoom
struct AvailableRoom: Codable, Identifiable {
    let id, bedType: String?
    let adults, children, maxOccupancy: Int?
    let amenities: [String]?
    let title, description: String?
    let pricePerNight: Double?
    let currency: String?
    let cover: Cover?
    let amenitiesRef: [AmenitiesRef]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bedType, adults, children, maxOccupancy, amenities, title, description, pricePerNight, currency, cover, amenitiesRef
    }
}

// MARK: - AmenitiesRef
struct AmenitiesRef: Codable, Identifiable {
    let id, name, category: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, category
    }
}

// MARK: - Cover
struct Cover: Codable, Identifiable {
    let id: String?
    let isCoverImage: Bool?
    let sourceURL, thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isCoverImage
        case sourceURL = "sourceUrl"
        case thumbnailURL = "thumbnailUrl"
    }
}

// MARK: - Booking
struct Booking: Codable {
    let status: String?
    let adults, children: Int?
    let childrenAge: [Int]?
    let bookedFor, id, checkIn, checkOut: String?
//    let guestDetails: [JSONAny]?
    let bookingID, userID, businessProfileID, createdAt: String?
    let updatedAt: String?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case status, adults, children, childrenAge, bookedFor
        case id = "_id"
        case checkIn, checkOut, bookingID, userID, businessProfileID, createdAt, updatedAt
        case v = "__v"
    }
}
