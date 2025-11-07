//
//  BlockedUsersViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 08/11/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class BlockedUsersViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = BlockedUsersDataManager()
    let profileDataManager = ProfileDataManager()
    @Published var blockedUsersArray: [SearchProfileData] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var pageNumber: Int = 1
    @Published var totalPages: Int = 1
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func showUserProfile(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showUnblockModal(id: String) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_really_want_to_unblock_this_user".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) { [weak self] in
                guard let self else { return }
                unBlockUser(id: id)
                
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func removeProfileFromBlocked(id: String) {
        if let index = blockedUsersArray.firstIndex(where: { $0.id == id}) {
            blockedUsersArray.remove(at: index)
        }
    }
}

// MARK: - Networking
extension BlockedUsersViewModel {
    
    func getBlockedUsers(refreshData: Bool = false) {
        guard pageNumber <= totalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBlockedUsers(pageNo: pageNumber)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if refreshData {
                                blockedUsersArray = data
                            } else {
                                blockedUsersArray.append(contentsOf: data)
                            }
                        }
                        
                        pageNumber = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
                    }
                }
                
            } catch {
                
            }
        }
    }
    
    
    func unBlockUser(id: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await profileDataManager.blockUser(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        removeProfileFromBlocked(id: id)
                    }
                }
            } catch {
                
            }
        }
    }
}
