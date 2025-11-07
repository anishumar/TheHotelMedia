//
//  SubscriptionPlan.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation



struct SubscriptionPlanResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SubscriptionPlan]?
}

struct SubscriptionPlan: Codable, Identifiable, Hashable {
    let id: String?
    let features, businessSubtypeID, businessTypeID: [String]?
    let name, description, appleSubscriptionID: String?
    let price: Int?
    let duration: String?
    let image: String?
    let type, level, currency, createdAt: String?
    let updatedAt: String?
}
