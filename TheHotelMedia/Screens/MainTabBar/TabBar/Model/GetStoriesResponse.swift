//
//  GetStoriesResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import Foundation
import UIKit

// MARK: - Welcome
struct GetStoriesResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: StoriesData?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - DataClass
struct StoriesData: Codable {
    let myStories: [MyStory]?
    let stories: [StoryUser]?
}

// MARK: - MyStory
struct MyStory: Codable, Identifiable {
    let id, mediaID, createdAt, mimeType: String?
    let sourceURL: String?
    let thumbnailUrl: String?
    let likesRef: [StoryLikeRef]?
    let viewsRef: [StoryLikeRef]?
    let likedByMe: Bool?
    let seenByMe: Bool?
    let duration: Double?
    let mentions: [String]?
    var videoThumbnail: UIImage? = nil

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mediaID, createdAt, mimeType
        case sourceURL = "sourceUrl"
        case likesRef
        case viewsRef
        case likedByMe
        case seenByMe
        case duration
        case mentions
        case thumbnailUrl
    }
}

// MARK: - Story
struct StoryUser: Codable {
    let id: String?
    let accountType: String?
    let profilePic: ProfilePic?
    let seenByMe: Bool?
    let username, name: String?
    let storiesRef: [MyStory]?
    let businessProfileRef: BusinessProfileRef?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, profilePic, username, name, storiesRef, businessProfileRef, seenByMe
    }
}

struct StoryLikeRef: Codable, Identifiable, Equatable, Hashable {
    let username: String?
    let profilePic: ProfilePic?
    let accountType: String?
    let name: String?
    let id: String?
    let businessProfileRef: BusinessProfileRef?

    enum CodingKeys: String, CodingKey {
        case username
        case profilePic
        case accountType
        case name
        case businessProfileRef
        case id = "_id"
    }
}

