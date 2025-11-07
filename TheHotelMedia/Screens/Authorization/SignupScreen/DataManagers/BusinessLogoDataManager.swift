//
//  BusinessLogoDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import UIKit


class BusinessLogoDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func uploadProfilePic(uiImage: UIImage, parameters: [String: Any] ) async throws -> IndividualProfilePicResponse {
        let resource = Resource<IndividualProfilePicResponse>(url: .profilePic, method: .postImage(uiImage, parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func uploadPropertyImages(files: [FileModel]) async throws -> PropertyImagesResponse {
        
        let resource = Resource<PropertyImagesResponse>(url: .uploadPropertyImages, method: .postFiles(files))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
