//
//  SuggestionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

// MARK: - SuggestionResponse
struct SuggestionResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [Suggestion]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - Suggestion
struct Suggestion: Codable, Identifiable {
    let id: String?
    let rating: Double?
    let profilePic: ProfilePic?
    let name: String?
    let address: Address?
    let businessTypeRef: BusinessTypeRef?
    let businessSubtypeRef: BusinessSubtypeRef?
    let userID: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case rating, profilePic, name, address, businessTypeRef, businessSubtypeRef, userID
    }
}
