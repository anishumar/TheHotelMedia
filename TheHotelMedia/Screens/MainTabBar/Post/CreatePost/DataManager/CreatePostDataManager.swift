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
    
    func updatePost(postID: String, attachments: [MediaAttachment], tagged: [String], parameters: [String: Any], deletedMedia: [String]) async throws -> CreatePostResponse {
        
        guard let url = URL(string: "\(URL.updatePost.absoluteString)\(postID)") else { throw NetworkError.badURL }
        
        let resource = Resource<CreatePostResponse>(url: url, method: .updatePost(attachments, tagged, parameters, deletedMedia))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
}
