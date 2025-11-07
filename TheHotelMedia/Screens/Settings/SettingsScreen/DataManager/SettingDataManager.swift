//
//  SettingDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 28/10/24.
//

import Foundation


class SettingDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func deactivateAccount() async throws -> DeactivateAccountResponse {
        let resource = Resource<DeactivateAccountResponse>(url: .disableAccount, method: .patch([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func deleteAccount() async throws -> DeleteAccountResponse {
        let resource = Resource<DeleteAccountResponse>(url: .deleteAccount, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func logoutAccount() async throws -> LogoutResponse {
        let resource = Resource<LogoutResponse>(url: .logout, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
