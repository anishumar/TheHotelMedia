//
//  SubscriptionMetaResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 22/01/25.
//

import Foundation

// MARK: - SubscriptionMetaResponse
struct SubscriptionMetaResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: MetaData?
}

// MARK: - DataClass
struct MetaData: Codable {
    let uploadLimit: [UploadLimit]?
    let hasSubscription: Bool?
}

// MARK: - UploadLimit
struct UploadLimit: Codable {
    let fileType, unit: String?
    let size: Int?
}
