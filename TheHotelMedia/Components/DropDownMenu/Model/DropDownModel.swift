//
//  DropDown.swift
//  HotelMedia
//
//  Created by MAC on 23/08/24.
//

import Foundation


struct DropDownModel: Decodable, Identifiable, Equatable {
    let id: String
    var answer: [String]
    var question: String
    var selectedAnswer: String? = nil
}
