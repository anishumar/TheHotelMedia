//
//  BookingCheckoutResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 21/02/25.
//

import Foundation

// MARK: - BookingCheckoutResponse
struct BookingCheckoutResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: BookingCheckoutData?
}

// MARK: - CheckoutData
struct BookingCheckoutData: Codable {
    let id, status: String?
    let adults: Int?
    let childrenAge: [Int]?
    let isTravellingWithPet: Bool?
    let bookedFor, checkIn, checkOut: String?
//    let guestDetails: [JSONAny]?
    let bookingID, userID, businessProfileID, createdAt: String?
    let updatedAt: String?
    let v, children: Int?
    let bookedRoom: BookedRoom?
    let razorPayOrderID: String?
    let user: User?
    let razorPayOrder: RazorPayOrder?
    let businessProfileRef: BusinessProfileRef?
    let payment: BookingPayment?
    let room: Room?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status, adults, childrenAge, isTravellingWithPet, bookedFor, checkIn, checkOut, bookingID, userID, businessProfileID, createdAt, updatedAt
        case v = "__v"
        case children, bookedRoom, razorPayOrderID, user, razorPayOrder, businessProfileRef, payment, room
    }
}

// MARK: - BookedRoom
struct BookedRoom: Codable {
    let roomID: String?
    let price, quantity, nights: Int?
}


// MARK: - Notes
struct Notes: Codable {
    let description: String?
}

// MARK: - Room
struct Room: Codable {
    let title, bedType: String?
}

// MARK: - User
struct User: Codable {
    let email, fullName, mobileNumber, name, dialCode, phoneNumber: String?
    var mobileVerified: Bool?
}

// MARK: - Payment
struct BookingPayment: Codable {
    let subtotal: Double?
    let gst, total: Double?
    let promocode: BookingPromoCode?
    let gstRate: Double?
    let convinceCharges: Double?
    let discount: Double?
}

// MARK: - PromoCode
struct BookingPromoCode: Codable {
    let description: String?
    let name: String?
}
