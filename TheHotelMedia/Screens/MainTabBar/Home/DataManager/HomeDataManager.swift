//
//  HomeDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 08/10/24.
//

import Foundation



struct HomeDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getHomeData(pageNo: Int, suggestion: Bool, lat: Double, lng: Double) async throws -> HomeDataResponse {
        
//        let url = URL(string: URL.getHome.absoluteString + "?pageNo=\(pageNo)")!
        let resource: Resource<HomeDataResponse>
        if suggestion {
            resource = Resource<HomeDataResponse>(url: .getHome, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10"), URLQueryItem(name: "suggestion", value: suggestion.description), URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lng", value: "\(lng)")]))
        } else {
            resource = Resource<HomeDataResponse>(url: .getHome, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10"), URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lng", value: "\(lng)")]))
        }
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getSubscriptionMeta() async throws -> SubscriptionMetaResponse {
        
        let resource = Resource<SubscriptionMetaResponse>(url: .getSubscriptionMeta, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
