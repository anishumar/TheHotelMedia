//
//  SavedPostDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 15/10/24.
//

import Foundation


class SavedPostDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getSavedPost(pageNo: Int) async throws -> SavedPostResponse {
        
        let resource = Resource<SavedPostResponse>(url: .savedPosts, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
