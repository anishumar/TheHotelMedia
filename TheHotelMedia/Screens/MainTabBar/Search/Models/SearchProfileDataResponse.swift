//
//  SearchProfileDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 16/10/24.
//

import Foundation


struct SearchProfileDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SearchProfileData]?
    let pageNo, totalPages, totalResources: Int?
}


struct SearchProfileData: Codable, Identifiable, Hashable {
    let id: String
    let accountType: String?
    let profilePic: ProfilePic?
    let username: String?
    let name: String?
    let role: String?
    let businessProfileRef: Ref?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, profilePic, username, name, businessProfileRef, role
    }
}
