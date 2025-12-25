//
//  RestaurantMenuResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import Foundation

struct RestaurantMenuResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [MenuItem]?
}

struct MenuItem: Codable, Identifiable, Hashable {
    let id: String
    let businessProfileID: String?
    let userID: String?
    let mediaID: String?
    let createdAt: String?
    let updatedAt: String?
    let media: MenuItemMedia?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case businessProfileID, userID, mediaID, createdAt, updatedAt, media
    }
}

extension MenuItem {
    // Custom coding keys for GET response vs POST response
    // The GET response has 'id' and the POST response has '_id'
    // Actually the docs show 'id' in GET success and '_id' in POST success.
    // I will handle both.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idVal = try container.decodeIfPresent(String.self, forKey: .id) {
            id = idVal
        } else {
            // Fallback to searching for 'id' if '_id' is not present
            struct IDContainer: Codable { let id: String? }
            let idContainer = try IDContainer(from: decoder)
            id = idContainer.id ?? ""
        }
        businessProfileID = try container.decodeIfPresent(String.self, forKey: .businessProfileID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        mediaID = try container.decodeIfPresent(String.self, forKey: .mediaID)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        media = try container.decodeIfPresent(MenuItemMedia.self, forKey: .media)
    }
}

struct MenuItemMedia: Codable, Hashable {
    let id: String?
    let mediaType: String?
    let sourceUrl: String?
    let thumbnailUrl: String?
    let mimeType: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mediaType, sourceUrl, thumbnailUrl, mimeType
    }
}

extension MenuItemMedia {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idVal = try container.decodeIfPresent(String.self, forKey: .id) {
            id = idVal
        } else {
            struct IDContainer: Codable { let id: String? }
            let idContainer = try IDContainer(from: decoder)
            id = idContainer.id
        }
        mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
    }
}
