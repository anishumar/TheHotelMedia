//
//  RandomProfile.swift
//  HotelMedia
//
//  Created by MAC on 05/08/24.
//

import Foundation


struct RandomImages: Codable, Identifiable {
    let id = UUID().uuidString
    let results: [OtherResult]
    
}


struct OtherResult: Codable {
    let picture: Pictures
}

struct Pictures: Codable {
    let medium: String?
}
