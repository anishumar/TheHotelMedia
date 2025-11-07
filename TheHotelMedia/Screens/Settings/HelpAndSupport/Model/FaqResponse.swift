//
//  FaqResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 25/10/24.
//

import Foundation

// MARK: - Welcome
struct FaqResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [QuestionAnswer]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - Datum
struct QuestionAnswer: Codable, Identifiable {
    let id, question, answer: String?
    var isExpanded: Bool? = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case question, answer
    }
}



