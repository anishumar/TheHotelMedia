//
//  HomeDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 08/10/24.
//

import Foundation
import UIKit


struct HomeDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [PostData]?
    let pageNo, totalPages, totalResources: Int?
}


// MARK: - PostData
struct PostData: Codable, Identifiable, Equatable, Hashable {
    let usingID: String = UUID().uuidString
    let id: String?
    var data: [ReviewedBusinessProfileRef]?
    let isPublished: Bool?
    let feelings: String?
    let googleReviewedBusiness: String?
    let publicUserID: String?
    let reviews: [Review]?
    let businessProfileID: String?
    let postType: String?
    let userID, content: String?
    let location: Location?
    let createdAt: String?
    let mediaRef: [MediaRef]?
    let taggedRef: [TaggedRef]?
    let postedBy: PostedBy?
    var likes, comments: Int?
    var likedByMe, savedByMe: Bool?
    let reviewedBusinessProfileID, placeID: String?
    let rating: Double?
    let reviewedBusinessProfileRef: ReviewedBusinessProfileRef?
    let name: String?
    let startTime: String?
    let startDate: String?
    let venue: String?
    let type: String?
    var refreshPost: Bool?
    
    // New properties based on JSON
    let endDate: String?
    let endTime: String?
    let streamingLink: String?
    let shared: Int?
    let views: Int?
    var imJoining: Bool?
    let placeName: String?
    let commentsCount: Int? // For 'comments'
    var interestedPeople: Int? // For 'comments'
    var eventJoinsRef: [JoinProfileRef]?
    var collaboratorRef: [TaggedRef]?
    var isExpandedDescription: Bool = false
    var currentPage: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isPublished, feelings, reviews, businessProfileID, postType, userID, content, location, createdAt, mediaRef, taggedRef, postedBy, likes, comments, likedByMe, savedByMe, reviewedBusinessProfileID, placeID, rating, reviewedBusinessProfileRef, name, startTime, startDate, venue, refreshPost
        case endDate, endTime, streamingLink, shared, imJoining, placeName, commentsCount, interestedPeople, eventJoinsRef, type, data, views, googleReviewedBusiness, publicUserID, collaboratorRef
    }
}


struct Review: Codable, Equatable, Hashable {
    let questionID: String?
    let rating: Int?
}


struct JoinProfileRef: Codable, Identifiable, Hashable {
    let id: String
    let profilePic: ProfilePic?
    
    enum CodingKeys: String, CodingKey {
        case id = "userID"
        case profilePic
    }
}


struct TaggedRef: Codable, Identifiable, Hashable {
    let id: String
    let profilePic: ProfilePic?
    let accountType: String?
    let name: String?
    let role: String?
    let username: String?
    let businessProfileRef: BusinessProfileRef?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case profilePic, name, accountType, businessProfileRef, username, role
    }
}



struct ReviewedBusinessProfileRef: Codable, Equatable, Hashable, Identifiable {
    let id: String?
    let profilePic: ProfilePic?
    let name: String?
    let address: Address?
    let businessTypeRef: BusinessTypeRef?
    let businessSubtypeRef: BusinessSubtypeRef?
    let coverImage: String?
    let userID: String?
    let rating: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case profilePic, name, address, businessTypeRef, businessSubtypeRef, coverImage, rating, userID
    }
}


// MARK: - Location
struct Location: Codable, Equatable, Hashable {
    let lat, lng: Double?
    let placeName: String?
}

// MARK: - MediaRef
struct MediaRef: Codable, Equatable, Identifiable, Hashable {
    let id: String?
    let mediaType: String?
    let mimeType: String?
    let sourceURL: String?
    let thumbnailURL: String?
    let views: Int?
    var videoThumbnail: UIImage? = nil
    var postID: String? = ""  // Setting this value on our own.
    var postType: String? = ""  // Setting this value on our own.

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mediaType, mimeType
        case sourceURL = "sourceUrl"
        case thumbnailURL = "thumbnailUrl"
        case views
    }
}


// MARK: - PostedBy
struct PostedBy: Codable, Equatable, Hashable {
    let id: String?
    let accountType: String?
    let businessProfileID, name, username: String?
    let businessProfileRef: Ref?
    let profilePic: ProfilePic?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, businessProfileID, name, businessProfileRef, profilePic, username
    }
}


// MARK: - BusinessTypeRef
struct BusinessTypeRef: Codable, Equatable, Hashable {
    let id: String?
    let icon: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case icon, name
    }
}


