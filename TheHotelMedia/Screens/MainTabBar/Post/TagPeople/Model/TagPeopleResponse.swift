//
//  TagPeopleResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 14/10/24.
//

import Foundation


struct TagPeopleResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SearchProfile]?
    let pageNo, totalPages, totalResources: Int?
}
