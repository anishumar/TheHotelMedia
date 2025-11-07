//
//  BookingDetail.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import Foundation


struct BookingDetail {
    let fromDate: Date
    let toDate: Date
    let fromDateString: String
    let toDateString: String
    let toShowGuestString: String
    let toShowAddressString: String
    let guestCount: Int
    let withPet: Bool
    var childrenCount: Int? = nil
    var ageArray: [Int?]? = nil
}
