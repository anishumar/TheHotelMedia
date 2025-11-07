//
//  SearchDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 16/10/24.
//

import Foundation


class SearchDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getSearchProfileResults(query: String = "", pageNo: Int, selectedTypes: [TypeModel], isnearby: Bool, lat: Double? = nil, lng: Double? = nil, radius: Double = 50) async throws -> SearchProfileDataResponse {
        
        var queries: [URLQueryItem] = [URLQueryItem(name: "query", value: query), URLQueryItem(name: "type", value: isnearby ? "business" : "users"), URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "radius", value: "\(radius)")]
        
        if selectedTypes.isNotEmpty {
            for type in selectedTypes {
                queries.append(URLQueryItem(name: "businessTypeID", value: type.id ?? ""))
            }
        }
        
        if let lat, let lng {
            queries.append(URLQueryItem(name: "lat", value: "\(lat)"))
            queries.append(URLQueryItem(name: "lng", value: "\(lng)"))
        }
        
        
        let resource = Resource<SearchProfileDataResponse>(url: .search, method: .get(queries))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getSearchPostResults(query: String = "", type: String = "posts", pageNo: Int, selectedTypes: [TypeModel], lat: Double? = nil, lng: Double? = nil, radius: Double = 50) async throws -> SearchPostDataResponse {
        
        var queries: [URLQueryItem] = [URLQueryItem(name: "query", value: query), URLQueryItem(name: "type", value: type), URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10"), URLQueryItem(name: "radius", value: "\(radius)")]
        
        if selectedTypes.isNotEmpty {
            for type in selectedTypes {
                queries.append(URLQueryItem(name: "businessTypeID", value: type.id ?? ""))
            }
        }
        
        if let lat, let lng {
            queries.append(URLQueryItem(name: "lat", value: "\(lat)"))
            queries.append(URLQueryItem(name: "lng", value: "\(lng)"))
        }
        
        let resource = Resource<SearchPostDataResponse>(url: .search, method: .get(queries))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
