//
//  IndividualProfilePicResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import Foundation


struct IndividualProfilePicResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
