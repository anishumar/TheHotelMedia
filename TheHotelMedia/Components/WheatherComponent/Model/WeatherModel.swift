//
//  WheatherModel.swift
//  TheHotelMedia
//
//  Created by MAC on 10/01/25.
//

import Foundation

// MARK: - Welcome
struct WeatherModel: Codable, Equatable, Hashable {
    let coord: Coord?
    let weather: [Weather]?
//    let base: String?
    let main: Main?
//    let visibility: Int?
//    let wind: Wind?
//    let clouds: Clouds?
//    let dt: Int?
//    let sys: Sys?
//    let timezone, id: Int?
//    let name: String?
//    let cod: Int?
}

//// MARK: - Clouds
//struct Clouds: Codable {
//    let all: Int?
//}
//
// MARK: - Coord
struct Coord: Codable, Equatable, Hashable {
    let lon, lat: Double?
}

// MARK: - Main
struct Main: Codable, Equatable, Hashable {
    let temp: Double?
    let feelsLike, tempMax: Double?
//    let feelsLike, tempMin, tempMax: Double?
//    let pressure, humidity, seaLevel, grndLevel: Int?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
//        case tempMin = "temp_min"
        case tempMax = "temp_max"
//        case pressure, humidity
//        case seaLevel = "sea_level"
//        case grndLevel = "grnd_level"
    }
}

//// MARK: - Sys
//struct Sys: Codable {
//    let country: String?
//    let sunrise, sunset: Int?
//}
//
// MARK: - Weather
struct Weather: Codable, Equatable, Hashable {
    let id: Int?
    let main, description, icon: String?
}
//
//// MARK: - Wind
//struct Wind: Codable {
//    let speed: Double?
//    let deg: Int?
//    let gust: Double?
//}
