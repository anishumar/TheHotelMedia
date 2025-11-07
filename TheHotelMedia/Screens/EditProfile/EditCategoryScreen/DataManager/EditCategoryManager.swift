//
//  EditCategoryManager.swift
//  TheHotelMedia
//
//  Created by MAC on 30/09/24.
//

import Foundation


class EditCategoryManager {
    
    let baseNetworkManager = BaseNetworkManager()
    
    
    func getBusinessType() async throws -> BusinessTypeResponse {
        let resource = Resource<BusinessTypeResponse>(url: .getBusinessTypes, method: .get([]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func getBusinessSubType(id: String) async throws -> BusinessSubTypeResponse {
        
        let string = URL.getBusinessSubTypes.absoluteString
        let resource = Resource<BusinessSubTypeResponse>(url: URL(string: "\(string)/\(id)")!, method: .get([]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func changeBusinessType(parameters: [String: Any]) async throws -> EditProfileResponse {
        let resource = Resource<EditProfileResponse>(url: .editProfile, method: .patch(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
