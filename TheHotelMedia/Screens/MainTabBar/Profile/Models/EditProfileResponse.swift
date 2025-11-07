//
//  EditProfileResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 27/09/24.
//

import Foundation


struct EditProfileResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: ProfileData?
}
