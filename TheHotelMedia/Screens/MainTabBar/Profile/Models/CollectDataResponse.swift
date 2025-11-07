//
//  CollectDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 21/11/24.
//

import Foundation


struct CollectDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
