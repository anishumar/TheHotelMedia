//
//  PlacesDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import Foundation


class PlacesDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getPlaces(querys: [URLQueryItem]) async throws -> GetPlacesResponse {
        
        let resource = Resource<GetPlacesResponse>(url: .getPlaces, method: .get(querys))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func getBusinessProfile(placeID: String, businessProfileID: String = "") async throws -> ProfileResponse {
        let urlString = URL.getBusinessProfile.absoluteString + placeID
        
        let resource = Resource<ProfileResponse>(url: URL(string: urlString)!, method: .get(businessProfileID.isEmpty ? [] : [URLQueryItem(name: "businessProfileID", value: businessProfileID)]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
