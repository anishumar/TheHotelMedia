//
//  GetTransactionsResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import Foundation


struct GetTransactionsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SubscriptionTransaction]?
    let pageNo, totalPages, totalResources: Int?
}


// MARK: - Transaction
struct SubscriptionTransaction: Codable, Identifiable {
    let id: String?
    let grandTotal: Double?
    let orderID, createdAt, updatedAt: String?
    let paymentDetail: PaymentDetail?
    let subscriptionPlanRef: SubscriptionPlanRef?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case grandTotal, orderID, createdAt, paymentDetail, subscriptionPlanRef, updatedAt
    }
}

// MARK: - PaymentDetail
struct PaymentDetail: Codable {
    let transactionID, paymentMethod: String?
    let transactionAmount: Double?
}

// MARK: - SubscriptionPlanRef
struct SubscriptionPlanRef: Codable {
    let id, name: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, image
    }
}
