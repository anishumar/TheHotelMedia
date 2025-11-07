//
//  BookingHistoryResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import Foundation

// MARK: - Welcome
struct BookingHistoryResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [BookingHistory]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - BookingHistory
struct BookingHistory: Codable, Identifiable {
    let id, status: String?
    let adults: Int?
    let childrenAge: [Int]?
    let isTravellingWithPet: Bool?
    let bookedFor: String?
    let subTotal, discount, tax, convinceCharge: Double?
    let grandTotal: Double?
    let checkIn, checkOut: String?
    let guestDetails: [GuestDetail]?
    let bookingID, userID, businessProfileID, createdAt, type: String?
    let updatedAt: String?
    let bookedRoom: BookedRoom?
    let children: Int?
    let razorPayOrderID, promoCode, promoCodeID: String?
    let roomsRef: RoomsRef?
    let usersRef: UsersRef?
    let businessProfileRef: BusinessProfileRef?
    let paymentDetail: PaymentDetail?
    let metadata: BookingMetadata?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status, adults, childrenAge, isTravellingWithPet, bookedFor, subTotal, discount, tax, convinceCharge, grandTotal, checkIn, checkOut, guestDetails, bookingID, userID, businessProfileID, createdAt, updatedAt, bookedRoom, children, razorPayOrderID, promoCode, promoCodeID, roomsRef, usersRef, businessProfileRef, paymentDetail, type, metadata
    }
}

struct BookingMetadata: Codable {
    let typeOfEvent: String?
}


// MARK: - GuestDetail
struct GuestDetail: Codable, Identifiable {
    let id = UUID().uuidString
    let title, fullName, email, mobileNumber: String?
}


// MARK: - RoomsRef
struct RoomsRef: Codable {
    let id, bedType, roomType, title: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bedType, roomType, title
    }
}
