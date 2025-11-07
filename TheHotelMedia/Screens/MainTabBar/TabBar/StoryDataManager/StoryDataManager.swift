//
//  StoryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import Foundation


class StoryDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    
    func postStory(attachments: [MediaAttachment]) async throws -> PostStoryResponse {
        
        let resource = Resource<PostStoryResponse>(url: .createStory, method: .createStory(attachments))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getStories(pageNo: Int) async throws -> GetStoriesResponse {
        
        let resource = Resource<GetStoriesResponse>(url: .getStories, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "38")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
