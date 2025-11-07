//
//  StorySeenViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//

import Foundation
import SwiftUI
import SwiftfulRouting

class StorySeenViewModel: ObservableObject {
    
    let storyID: String
    let dataManager = StoryInteractionDataManager()
    let profileDataManager = ProfileDataManager()
    @Published var selectedTab: String = "views"
    @Published var viewedByProfilesArray: [SearchProfileData] = []
    @Published var likedByProfilesArray: [SearchProfileData] = []
    @Published var storyViewsPageNo: Int = 1
    @Published var storyViewsTotalPages: Int = 1
    @Published var storyLikesPageNo: Int = 1
    @Published var storyLikesTotalPages: Int = 1
    @Published var totalViews: Int = 0
    @Published var totalLikes: Int = 0
    @Published var showLoadingIndicator: Bool = false
    @Published var showProfileOptions: Bool = false
    @Published var showBlockModal: Bool = false
    @Published var showRemoveFollowerModal: Bool = false
    @Published var selectedProfile: SearchProfileData? = nil
    
    init(storyID: String) {
        self.storyID = storyID
        getStoryViews()
        getStoryLikes()
    }
    
    
//    func showProfileOptionsModal(id: String, usename: String) {
//        
//    }
    
    func removeFollower(id: String) {
        blockUser(id: id)
        
        if let index = viewedByProfilesArray.firstIndex(where: { $0.id == id }) {
            viewedByProfilesArray.remove(at: index)
            totalViews -= 1
        }
        
        if let index2 = likedByProfilesArray.firstIndex(where: { $0.id == id }) {
            likedByProfilesArray.remove(at: index2)
            totalLikes -= 1
        }
    }
    
    
}


// MARK: - Networking
extension StorySeenViewModel {
    func getStoryViews() {
        
        guard storyViewsPageNo <= storyViewsTotalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getStoryViews(id: storyID, pageNo: storyViewsPageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            viewedByProfilesArray.append(contentsOf: data)
                        }
                    }
                    
                    storyViewsPageNo = result.pageNo ?? 1
                    storyViewsTotalPages = result.totalPages ?? 1
                    totalViews = result.totalResources ?? 1
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
    
    func getStoryLikes() {
        
        guard storyLikesPageNo <= storyLikesTotalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getStoryLikes(id: storyID, pageNo: storyLikesPageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            likedByProfilesArray.append(contentsOf: data)
                        }
                    }
                    
                    storyLikesPageNo = result.pageNo ?? 1
                    storyLikesTotalPages = result.totalPages ?? 1
                    totalLikes = result.totalResources ?? 1
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
    
    func blockUser(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let _ = try await profileDataManager.blockUser(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
            } catch {
                
            }
        }
    }
}
