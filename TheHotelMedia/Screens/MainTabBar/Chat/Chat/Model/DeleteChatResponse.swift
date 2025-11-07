//
//  DeleteChatResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/01/25.
//

import Foundation


struct DeleteChatResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
