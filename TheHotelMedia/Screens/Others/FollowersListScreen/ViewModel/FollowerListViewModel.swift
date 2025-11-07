//
//  FollowerListViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import SwiftUI
import SwiftfulRouting


class FollowerListViewModel: ObservableObject {
    
    var router: AnyRouter
    var id: String = ""
    var username: String = ""
    @Published var currentTab: String = "following"
    @Published var followersList: [SearchProfileData] = []
    @Published var followingList: [SearchProfileData] = []
    @Published var showLoadingIndicator: Bool = false
    
    @Published var followersPageNo: Int = 1
    @Published var followersTotalPages: Int = 1
    
    @Published var followingsPageNo: Int = 1
    @Published var followingsTotalPages: Int = 1
    
    var followingListYOffset: [CGFloat] = []
    var followerListYOffset: [CGFloat] = []
    
    @Published var selectedProfileID: String = ""
    @Published var profileOptionYoffset: CGFloat = 0
    @Published var showProfileOptions: Bool = false
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    let dataManager = UserConnectionsDataManager()
    let profileDataManager = ProfileDataManager()
    
    init(router: AnyRouter, id: String, username: String, currentTab: String) {
        self.router = router
        self.id = id
        self.username = username
        self.currentTab = currentTab
        
        getFollowers()
        getFollowings()
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension FollowerListViewModel {
    func getFollowers() {
        
        guard followersPageNo <= followersTotalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getfollowers(id: id, pageNo: followersPageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            var yOffsetArray: [CGFloat] = []
                            for _ in data {
                                yOffsetArray.append(0)
                            }
                            followerListYOffset += yOffsetArray
                            followersList += data
                        }
                        followersPageNo = result.pageNo ?? 1
                        followersTotalPages = result.totalPages ?? 1
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
    
    func reportProfile(id: String) {
        Task {
            do {
                let result = try await profileDataManager.reportProfile(id: id)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
//    func blockUser(id: String) {
//        Task {
//            do {
//                let result = try await profileDataManager.blockUser(id: id)
//                
//                await MainActor.run {
//                    let range = 200...204
//                    
//                    if result.status && range.contains(result.statusCode) {
//                        if let index = followersList.firstIndex(where: {$0.id == id}) {
//                            followersList.remove(at: index)
//                        }
//                        
//                        if let followingIndex = followingList.firstIndex(where: {$0.id == id}) {
//                            followingIndex
//                        }
//                    }
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
    
    
    func getFollowings() {
        
        guard followingsPageNo <= followingsTotalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getfollowing(id: id, pageNo: followingsPageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            var yOffsetArray: [CGFloat] = []
                            for _ in data {
                                yOffsetArray.append(0)
                            }
                            followingListYOffset += yOffsetArray
                            followingList += data
                        }
                        followingsPageNo = result.pageNo ?? 1
                        followingsTotalPages = result.totalPages ?? 1
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
}


