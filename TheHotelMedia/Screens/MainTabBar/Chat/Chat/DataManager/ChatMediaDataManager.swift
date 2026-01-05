//
//  ChatMediaDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 28/11/24.
//

import Foundation


class ChatMediaDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func uploadMedia(media: [MessageMedia], parameters: [String: Any]) async throws -> UploadChatMediaResponse {
        
        let resource = Resource<UploadChatMediaResponse>(url: .sendMessageMedia, method: .mediaMessage(media, parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }

    func uploadMedia(media: [MessageMedia], parameters: [String: Any], uploadProgress: ((Double) -> Void)?) async throws -> UploadChatMediaResponse {
        let resource = Resource<UploadChatMediaResponse>(url: .sendMessageMedia, method: .mediaMessage(media, parameters))
        let result = try await baseNetworkManager.accessLoad(resource, uploadProgress: uploadProgress)
        return result
    }
    
    
    func deleteChat(userID: String) async throws -> DeleteChatResponse {
        
        guard let url = URL(string: "\(URL.deleteChat.absoluteString)\(userID)") else { throw NetworkError.badURL }
        
        let resource = Resource<DeleteChatResponse>(url: url, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func exportChat(userID: String) async throws -> ExportChatResponse {
        
        guard let url = URL(string: "\(URL.exportChat.absoluteString)\(userID)") else { throw NetworkError.badURL }
        
        let resource = Resource<ExportChatResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
