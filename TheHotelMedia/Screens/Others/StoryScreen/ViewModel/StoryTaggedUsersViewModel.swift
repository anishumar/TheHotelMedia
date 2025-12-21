//
//  StoryTaggedUsersViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import Foundation
import SwiftfulRouting

class StoryTaggedUsersViewModel: ObservableObject {
    
    @Published var taggedUsers: [ProfileData] = []
    @Published var isLoading: Bool = false
    let userIDs: [String]
    let router: AnyRouter
    private let profileDataManager = ProfileDataManager()
    
    init(router: AnyRouter, userIDs: [String]) {
        self.router = router
        self.userIDs = userIDs
        fetchUsers()
    }
    
    func fetchUsers() {
        guard !userIDs.isEmpty else { return }
        isLoading = true
        
        Task {
            // Fetch users concurrently
            await withTaskGroup(of: ProfileData?.self) { group in
                for id in userIDs {
                    group.addTask {
                        do {
                            let response = try await self.profileDataManager.getPublicProfile(id: id)
                            // Check for success status
                            let range = 200...204
                            if response.status && range.contains(response.statusCode) {
                                return response.data
                            }
                        } catch {
                            print("Error fetching user \(id): \(error)")
                        }
                        return nil
                    }
                }
                
                var users: [ProfileData] = []
                for await user in group {
                    if let user = user {
                        users.append(user)
                    }
                }
                
                let finalUsers = users
                await MainActor.run {
                    self.taggedUsers = finalUsers
                    self.isLoading = false
                }
            }
        }
    }
    
    func navigateToProfile(user: ProfileData) {
        // Reuse UserProfileView or similar logic
        // Assuming publicProfileID is available in ProfileData
        if let id = user.id {
             router.showScreen(.push) { router in
                 UserProfileView(createPostOn: .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                     .environmentObject(ThemeManager.shared)
                     .navigationBarBackButtonHidden()
             }
        }
    }
    
    func dismiss() {
        router.dismissScreen()
    }
}
