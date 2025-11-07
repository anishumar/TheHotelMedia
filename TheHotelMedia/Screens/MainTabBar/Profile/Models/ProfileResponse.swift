//
//  ProfileResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 27/09/24.
//

import Foundation


// MARK: - ProfileResponse
struct ProfileResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    var data: ProfileData?
}

// MARK: - ProfileData
struct ProfileData: Codable, Equatable, Hashable {
    let posts, follower, following: Int?
    let profileCompleted: Double?
    let id, bio, accountType, type, booking: String?
    let isVerified, isApproved, isActivated, isDeleted: Bool?
    let hasProfilePicture, acceptedTerms: Bool?
    let email, username, name, dialCode, role: String?
    let phoneNumber, businessProfileID: String?
    var businessProfileRef: BusinessProfileRef?
    let profilePic: ProfilePic?
    let reviewQuestions: [ReviewQuestion]?
    let privateAccount: Bool?
    let notificationEnabled: Bool?
    let inMyFollowing: Bool?
    var isConnected: Bool?
    var isRequested: Bool?
    var isBlockedByMe: Bool?
    let address: GetAddress?
    let weather: ProfileWeather?
    
    enum CodingKeys: String, CodingKey {
        case posts, follower, following, profileCompleted
        case id = "_id"
        case bio, accountType, isVerified, isApproved, isActivated, isDeleted, hasProfilePicture, acceptedTerms, email, username, name, dialCode, phoneNumber, businessProfileID, businessProfileRef, profilePic, reviewQuestions, privateAccount, inMyFollowing, isConnected, isRequested, notificationEnabled, isBlockedByMe, address, role, type, booking, weather
    }
}

// MARK: - ProfilePic
struct ProfilePic: Codable, Equatable, Hashable {
    let small: String?
    let medium: String?
    let large: String?
}


struct BusinessProfileRef: Codable, Hashable, Equatable {
    let id, bio: String?
    let website: String?
    let gstn: String?
    let amenities: [String]?
    let profilePic: ProfilePic?
    let username, businessTypeID, businessSubTypeID, name: String?
    let description: String?
    let address: GetAddress?
    let email, phoneNumber, dialCode: String?
    var placeID: String?
    let amenitiesRef: [Ref]?
    let businessTypeRef: Ref?
    let rating: Double?
    let businessSubtypeRef: BusinessSubtypeRef?
    let businessAnswerRef: [AmenityAnswer]?
    let coverImage: String?
    let type: String?
    

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bio, website, gstn, amenities, profilePic, username, businessTypeID, businessSubTypeID, name, description, address, email, phoneNumber, dialCode, placeID, amenitiesRef, businessTypeRef, businessSubtypeRef, businessAnswerRef, coverImage, type, rating
    }
}


// MARK: - Ref
struct Ref: Codable, Identifiable, Equatable, Hashable {
    let id: String?
    let icon: String?
    let name: String?
    let order: Int?
    let profilePic: ProfilePic?
    let businessTypeRef: BusinessTypeRef?
    let businessSubtypeRef: BusinessSubtypeRef?
    let rating: Double?
    let address: Address?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case icon, name, order, profilePic, businessTypeRef, businessSubtypeRef, rating, address
    }
}

// MARK: - BusinessSubtypeRef
struct BusinessSubtypeRef: Codable, Equatable, Hashable {
    let id, name: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}


struct ReviewQuestion: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let question: String
}

// MARK: - ProfileWeather
struct ProfileWeather: Codable, Equatable, Hashable {
    let wind: Wind?
    let base: String?
    let cod: Int?
    let sys: Sys?
    let timezone: Int?
    let coord: Coord?
    let id: Int?
    let airPollution: AQIModel?
    let main: Main?
    let weather: [Weather]?
    let dt: Int?
    let clouds: Clouds?
    let visibility: Int?
    let name: String?
}

// MARK: - Clouds
struct Clouds: Codable, Equatable, Hashable {
    let all: Int?
}

// MARK: - Sys
struct Sys: Codable, Equatable, Hashable {
    let country: String?
    let sunset, sunrise: Int?
}

// MARK: - Wind
struct Wind: Codable, Equatable, Hashable {
    let gust, speed: Double?
    let deg: Int?
}

