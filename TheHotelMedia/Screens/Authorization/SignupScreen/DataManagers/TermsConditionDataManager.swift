//
//  TermsConditionDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import SwiftUI


class TermsConditionDataManager {
    
    @AppStorage("accessToken") var accessToken: String = ""
    let baseNetworkManager = BaseNetworkManager.shared
    
    func acceptedTerms() async throws -> TermsResponse {
        
        let parameter = ["acceptedTerms": true]
        
        let header = [
            "Content-Type": "application/json",
            "x-access-token": accessToken
        ]
        
        let resource = Resource<TermsResponse>(url: .editProfile, headers: header, method: .patch(parameter))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
