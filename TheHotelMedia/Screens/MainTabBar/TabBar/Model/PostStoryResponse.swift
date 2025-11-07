//
//  PostStoryReponse.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import Foundation


struct PostStoryResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
