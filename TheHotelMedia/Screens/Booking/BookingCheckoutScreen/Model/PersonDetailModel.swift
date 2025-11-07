//
//  PersonDetailModel.swift
//  TheHotelMedia
//
//  Created by MAC on 19/02/25.
//

import Foundation


struct PersonDetailModel: Identifiable {
    let id: String = UUID().uuidString
    var title: String
    var name: String
    var email: String
    var phoneNumber: String
    var dialCode: String
    var isSelf: Bool = false
}
