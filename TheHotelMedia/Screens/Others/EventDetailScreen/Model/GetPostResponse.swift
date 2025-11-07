//
//  GetPostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/11/24.
//

import Foundation


struct GetPostResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: PostData?
}
