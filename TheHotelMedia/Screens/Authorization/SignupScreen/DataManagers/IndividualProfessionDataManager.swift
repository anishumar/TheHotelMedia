//
//  IndividualProfessionDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 31/12/24.
//

import Foundation


class IndividualProfessionDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getProfessions() async throws -> ProfessionResponse {
        
        let resource = Resource<ProfessionResponse>(url: .getProfessions, method: .get([]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func updateProfession(profession: String) async throws -> UpdateProfessionResponse {
        
        let resource = Resource<UpdateProfessionResponse>(url: .editProfile, method: .patch(["profession": profession]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
