//
//  WheatherDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 10/01/25.
//

import Foundation


class WeatherDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getWeatherData(lat: Double, lng: Double) async throws -> WeatherModel {
        
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather") else { throw NetworkError.badURL }
        
        let resource = Resource<WeatherModel>(url: url, method: .get([URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lon", value: "\(lng)"), URLQueryItem(name: "appid", value: "14fda30b266c2f4f5aa64d08344926a6")]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func getAQIData(lat: Double, lng: Double) async throws -> AQIModel {
        
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/air_pollution") else { throw NetworkError.badURL }
        
        let resource = Resource<AQIModel>(url: url, method: .get([URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lon", value: "\(lng)"), URLQueryItem(name: "appid", value: "14fda30b266c2f4f5aa64d08344926a6")]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
