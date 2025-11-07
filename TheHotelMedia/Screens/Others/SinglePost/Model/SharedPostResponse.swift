//
//  SharedPostResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 05/12/24.
//

import Foundation


struct SharedPostResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: PostData?
}
