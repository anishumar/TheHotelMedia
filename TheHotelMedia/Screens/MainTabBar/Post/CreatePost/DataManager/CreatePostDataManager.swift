//
//  CreatPostDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/10/24.
//

import Foundation


class CreatePostDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    let backgroundNetworkManager = BackgroundNetworkManager.shared
    
    func createPost(attachments: [MediaAttachment], tagged: [String], parameters: [String: Any]) async throws -> CreatePostResponse {
        
        let resource = Resource<CreatePostResponse>(url: .createPost, method: .createPost(attachments, tagged, parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func createPostBackground(attachments: [MediaAttachment], tagged: [String], parameters: [String: Any]) {
        backgroundNetworkManager.startUpload(attachments: attachments, tags: tagged, parameters: parameters)
    }
    
}
