//
//  CreateJobPostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation


struct CreateJobPostResponse: Refreshable, Codable {
    var status: Bool
    var statusCode: Int
    var message: String
}
