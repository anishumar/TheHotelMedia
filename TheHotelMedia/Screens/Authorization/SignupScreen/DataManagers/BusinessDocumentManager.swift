//
//  BusinessDocumentManager.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import Foundation


class BusinessDocumentManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func uploadDocuments(files: [FileModel] ) async throws -> BusinessDocumentResponse {
        
        let resource = Resource<BusinessDocumentResponse>(url: .businessDocuments, method: .postFiles(files))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
