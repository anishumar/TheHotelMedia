//
//  TagPeopleDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 14/10/24.
//

import Foundation



class TagPeopleDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getTagPeople(pageNo: Int, query: String = "") async throws -> TagPeopleResponse {
        let resource = Resource<TagPeopleResponse>(url: .getTagPeople, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "20"), URLQueryItem(name: "query", value: "\(query)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
