//
//  BusinessSubTypeResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import Foundation


struct BusinessSubTypeResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [SubTypeModel]?
}

struct SubTypeModel: Codable, Identifiable {
    let id: String?
    let name: String?
    let businessTypeID: String?
}
