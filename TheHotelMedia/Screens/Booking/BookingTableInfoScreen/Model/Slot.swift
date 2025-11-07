//
//  Slot.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import Foundation


struct Slot: Identifiable {
    let id = UUID().uuidString
    let time: String
    var isSelected: Bool = false
}
