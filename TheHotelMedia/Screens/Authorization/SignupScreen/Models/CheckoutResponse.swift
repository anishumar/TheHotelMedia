//
//  CheckoutResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


// MARK: - Welcome
struct CheckoutResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: CheckoutData?
}

// MARK: - CheckoutData
struct CheckoutData: Codable {
    let orderID: String?
    let razorPayOrder: RazorPayOrder?
    let billingAddress: BillingAddress?
    let plan: Plan?
    let payment: Payment?
}

// MARK: - BillingAddress
struct BillingAddress: Codable {
    let name: String?
    let address: GetAddress?
    let dialCode, phoneNumber, gstn: String?
}

// MARK: - Address
struct GetAddress: Codable, Hashable {
    let geoCoordinate: GeoCoordinate?
    let street, city, state, zipCode: String?
    let country: String?
    let lat, lng: Double?
}

// MARK: - GeoCoordinate
struct GeoCoordinate: Codable, Hashable {
    let type: String?
    let coordinates: [Double]?
}

// MARK: - Payment
struct Payment: Codable {
    let subtotal: Double?
    let gst, total: Double?
    let promoCode: PromoCode?
    let gstRate: Double?
    let convinceCharges: Double?
}

// MARK: - PromoCode
struct PromoCode: Codable {
    let code: String
    let priceType: String
    let description: String
    let name: String
    let value: Double
}

// MARK: - Plan
struct Plan: Codable {
    let id, name: String?
    let price: Int?
    let image: String?
    let duration: String?
}


// MARK: - RazorPayOrder
struct RazorPayOrder: Codable {
    let amount: Int?
    let amountDue: Int?
    let amountPaid: Int?
    let attempts: Int?
    let createdAt: Int?
    let currency: String?
    let entity: String?
    let id: String?
//    let notes: [String]?
    let offerId: String?
    let receipt: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case amountDue = "amount_due"
        case amountPaid = "amount_paid"
        case attempts
        case createdAt = "created_at"
        case currency
        case entity
        case id
//        case notes
        case offerId = "offer_id"
        case receipt
        case status
    }
}

