//
//  RestaurantMenuDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import Foundation

class RestaurantMenuDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getRestaurantMenu(businessProfileID: String) async throws -> RestaurantMenuResponse {
        let url = URL.getRestaurantMenu(businessProfileID: businessProfileID)
        let resource = Resource<RestaurantMenuResponse>(url: url, method: .get([]))
        return try await baseNetworkManager.accessLoad(resource)
    }
    
    func uploadRestaurantMenu(fileURLs: [URL]) async throws -> RestaurantMenuResponse {
        let url = URL.restaurantMenu
        let resource = Resource<RestaurantMenuResponse>(url: url, method: .uploadRestaurantMenu(fileURLs))
        return try await baseNetworkManager.accessLoad(resource)
    }
    
    func deleteRestaurantMenuItem(id: String) async throws -> RestaurantMenuResponse {
        let url = URL.deleteRestaurantMenuItem(id: id)
        let resource = Resource<RestaurantMenuResponse>(url: url, method: .delete)
        return try await baseNetworkManager.accessLoad(resource)
    }
}
