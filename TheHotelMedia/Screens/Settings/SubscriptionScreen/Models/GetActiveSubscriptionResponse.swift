//
//  GetActiveSubscriptionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 18/11/24.
//

import Foundation


struct GetActiveSubscriptionResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: GetActiveSubscriptionData?
}

struct GetActiveSubscriptionData: Codable {
    let subscription: ActiveSubscription?
}


struct ActiveSubscription: Codable {
    let id, businessProfileID, userID, subscriptionPlanID: String?
    let expirationDate, createdAt, updatedAt, name: String?
    let image: String?
    let remainingDays: Int?
    var hideCancelButton: Bool? = nil
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case businessProfileID, userID, subscriptionPlanID, expirationDate, createdAt, updatedAt, name, image, remainingDays
    }
}
