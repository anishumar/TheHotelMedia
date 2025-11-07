//
//  BookingSummaryResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import Foundation


// MARK: - BookingSummaryResponse
struct BookingSummaryResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: BookingSummary?
}

// MARK: - DataClass
struct BookingSummary: Codable {
    let id, status: String?
    let adults: Int?
    let childrenAge: [Int]?
    let isTravellingWithPet: Bool?
    let freeCancel: Bool?
    let bookedFor: String?
    let freeCancelBy: String?
    let gstRate: Double?
    let subTotal, discount, tax, convinceCharge: Double?
    let grandTotal: Double?
    let checkIn, checkOut: String?
    let guestDetails: [GuestDetail]?
    let bookingID, userID, businessProfileID, createdAt, type: String?
    let updatedAt: String?
    let bookedRoom: BookedRoom?
    let metadata: BookingMetadata?
    let children: Int?
    let razorPayOrderID, promoCode, promoCodeID: String?
    let paymentDetail: PaymentDetail?
    let roomsRef: RoomsRef?
    let usersRef: UsersRef?
    let businessProfileRef: BusinessProfileRef?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status, adults, childrenAge, isTravellingWithPet, bookedFor, subTotal, discount, tax, convinceCharge, grandTotal, checkIn, checkOut, guestDetails, bookingID, userID, businessProfileID, createdAt, updatedAt, bookedRoom, children, razorPayOrderID, promoCode, promoCodeID, paymentDetail, roomsRef, usersRef, businessProfileRef, freeCancelBy, gstRate, freeCancel, type, metadata
    }
}


// MARK: - RoomImagesRef
struct RoomImagesRef: Codable {
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

