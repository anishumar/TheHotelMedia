//
//  ProfessionResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 31/12/24.
//

import Foundation


struct ProfessionResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: [Profession]?
}

struct Profession: Codable, Hashable {
    var name: String?
}
