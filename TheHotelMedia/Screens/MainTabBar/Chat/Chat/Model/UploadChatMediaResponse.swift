//
//  UploadChatMediaResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 28/11/24.
//

import Foundation


struct UploadChatMediaResponse: Codable, Refreshable {
    let message: String
    let status: Bool
    let statusCode: Int
    let data: MessageResponse?
}

struct MessageResponse: Codable {
    let message: Message?
    let to: String?
}


struct Message: Codable {
    let type: String?
    let mediaID: String?
    let thumbnailUrl: String?
    let mediaUrl: String?
    let message: String?
}
