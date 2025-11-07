//
//  BusinessType.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import Foundation


struct BusinessTypeResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [TypeModel]?
}

struct TypeModel: Codable, Identifiable {
    let id: String?
    let icon: String?
    let name: String?
}

