//
//  BookTableResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 02/04/25.
//

import Foundation


// MARK: - BookTableResponse
struct BookTableResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: TableData?
}

// MARK: - TableData
struct TableData: Codable {
    let status: String?
    let adults, children: Int?
    let childrenAge: [Int]?
    let isTravellingWithPet: Bool?
    let bookedFor: String?
    let subTotal, discount, tax, convinceCharge: Int?
    let grandTotal: Int?
    let type, id, checkIn, checkOut: String?
    let guestDetails: [GuestDetail]?
    let bookingID, userID, businessProfileID, createdAt: String?
    let updatedAt: String?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case status, adults, children, childrenAge, isTravellingWithPet, bookedFor, subTotal, discount, tax, convinceCharge, grandTotal, type
        case id = "_id"
        case checkIn, checkOut, guestDetails, bookingID, userID, businessProfileID, createdAt, updatedAt
        case v = "__v"
    }
}
