//
//  DropDownModel2.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation


struct DropDownModel2: Codable, Identifiable, Equatable {
    let id: String
    var answer: [AnswerModel]
    var question: String
    var selectedAnswer: String? = nil
}

struct AnswerModel: Equatable, Codable {
    let option: String
    var icon: String? = nil
}



