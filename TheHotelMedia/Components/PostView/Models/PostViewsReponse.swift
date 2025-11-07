//
//  PostViewsReponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/01/25.
//

import Foundation


struct PostViewsReponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}
