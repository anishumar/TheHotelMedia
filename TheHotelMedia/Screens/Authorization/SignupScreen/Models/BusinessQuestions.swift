//
//  BusinessQuestions.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import Foundation



struct BusinessQuestionResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: [BusinessQuestion]?
}

struct BusinessQuestion: Codable {
    var id: String
    var answer: [String]?
    var question: String
}


struct BusinessQuestionPost: Codable {
    var questionID: String
    var answer: String?
}


struct BusinessQuestionPostResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
    var data: LoginData?
}
