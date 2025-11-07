//
//  AQIModel.swift
//  TheHotelMedia
//
//  Created by MAC on 10/01/25.
//

import Foundation


struct AQIModel: Codable, Equatable, Hashable {
    let coord: Coord?
    let list: [AQIList]?
}


// MARK: - List
struct AQIList: Codable, Equatable, Hashable {
    let main: AQIMain?
    let components: [String: Double]?
    let dt: Int?
}

// MARK: - Main
struct AQIMain: Codable, Equatable, Hashable {
    let aqi: Int?
}
