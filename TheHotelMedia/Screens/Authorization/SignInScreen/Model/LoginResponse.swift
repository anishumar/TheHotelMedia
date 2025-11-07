//
//  LoginResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import Foundation


struct LoginResponse: Codable {
    var status: Bool?
    var statusCode: Int?
    var message: String?
    var data: LoginData?
}


struct LoginData: Codable {
    var accountType: String?
    var profession: String?
    var role: String?
    var isVerified: Bool?
    var refreshToken: String?
    var accessToken: String?
    var hasProfilePicture: Bool?
    var acceptedTerms: Bool?
    var hasAmenities: Bool?
    var isDeleted: Bool?
    var hasSubscription: Bool?
    var isApproved: Bool?
    var isDocumentUploaded: Bool?
    var businessProfileRef: BusinessProfileReference?
}


struct BusinessProfileReference: Codable {
    var coverImage: String?
    var businessTypeID: String?
    var businessSubTypeID: String?
}
