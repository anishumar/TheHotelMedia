//
//  AmenityAnswer.swift
//  TheHotelMedia
//
//  Created by MAC on 30/09/24.
//

import Foundation


struct AmenityAnswer: Codable, Hashable {
    let id: String
    let questionID: String?
    let answer: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionID, answer
    }
}
