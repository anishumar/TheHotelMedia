//
//  StoryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import Foundation


class StoryDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    let notificationManager = StoryUploadNotificationManager.shared
    
    func postStory(attachments: [MediaAttachment], parameters: [String: Any] = [:]) async throws -> PostStoryResponse {
        
        // Send initial upload notification
        notificationManager.sendStoryUploadNotification(progress: 0.0)
        
        let resource = Resource<PostStoryResponse>(url: .createStory, method: .createStory(attachments, parameters))
        
        // Track upload progress
        var lastProgressUpdate: Double = 0.0
        
        let result = try await baseNetworkManager.accessLoad(resource) { progress in
            // Update notification every 10% progress to avoid spam
            let roundedProgress = Double(Int(progress * 10)) / 10.0
            if roundedProgress >= lastProgressUpdate + 0.1 || progress >= 0.99 {
                self.notificationManager.sendStoryUploadNotification(progress: progress)
                lastProgressUpdate = roundedProgress
            }
        }
        
        return result
    }
    
    
    func getStories(pageNo: Int) async throws -> GetStoriesResponse {
        
        let resource = Resource<GetStoriesResponse>(url: .getStories, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "38")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
