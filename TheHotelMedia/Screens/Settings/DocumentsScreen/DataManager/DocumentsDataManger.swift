//
//  DocumentsDataManger.swift
//  TheHotelMedia
//
//  Created by MAC on 06/12/24.
//

import Foundation


class DocumentsDataManger {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getDocuments() async throws -> GetBusinessDocumentsResponse {
        
        let resource = Resource<GetBusinessDocumentsResponse>(url: .getBusinessDocuments, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
