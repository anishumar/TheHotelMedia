//
//  Profile.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import Foundation


struct SearchProfile: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String?
    var username: String?
    var image: String?
    var profilePic: ProfilePic?
    var accountType: String?
    var role: String?
    var businessType: String?
    var isSelected: Bool? = false
    var businessProfileRef: Ref?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case role
        case username
        case image
        case profilePic
        case accountType
        case businessType
        case isSelected
        case businessProfileRef
    }
}
