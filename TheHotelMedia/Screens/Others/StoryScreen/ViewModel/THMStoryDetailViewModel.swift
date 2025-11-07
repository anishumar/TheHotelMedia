//
//  THMStoryDetailViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import Foundation
import SwiftfulRouting


class THMStoryDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = THMStoryDataManager()
    let profileDataManager = ProfileDataManager()
    var messageDataManager = ChatMediaDataManager()
    @Published var showLoadingIndicator: Bool = false
    @Published var showStoryLikes: Bool = false
    @Published var navigatingToProfile: Bool = false
    @Published var pauseVideo: Bool = false
    let socketViewModel = SocketIOViewModel.shared
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func sendMessage(message: String, mediaUrl: String, storyID: String, mediaID: String, username: String) {
        let messageModel: [String: Any] = [
            "type" : "story-comment",
            "message": message,
            "mediaUrl": mediaUrl,
            "mediaID": mediaID,
            "storyID": storyID
        ]
        
        let parameters: [String: Any] = [
            "message": messageModel,
            "to": username
        ]
        
        socketViewModel.sendMessage(parameters: parameters)
    }
    
    
    
    func showDeleteStoryModal(id: String, onDeleteStory: @escaping (() -> Void), onDismiss: @escaping (() -> Void) ) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "are_you_sure_you_want_to_delete_this_story?".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) { [weak self] in
                guard let self else { return }
                
                deleteStory(id: id) {
                    onDeleteStory()
                }
                
            } onRightButtonPressed: {
                onDismiss()
                
            } onDismiss: {
                onDismiss()
            }

    }
    
    
    func showProfileOptionsModal(id: String, onViewProfile: @escaping (() -> Void), onProfileBlock: @escaping (() -> Void), onDismiss: @escaping (() -> Void)) {
        BottomModalManager.verticalStyleModal(
            router: router,
            topButtonTitle: "block".localized(localizationManager.language),
            bottomButtonTitle: "view_profile".localized(localizationManager.language)) { [weak self] in
                guard let self else { return }
                blockUser(id: id)
                onProfileBlock()
                
            } onBottomButtonPressed: { [weak self] in
                guard let self else { return }
                showStoryUserProfile(id: id)
                onViewProfile()
                
            } onDismiss: {
                onDismiss()
            }

    }
    
    
    func showStoryUserProfile(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
        
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
}


// MARK: -  Networking
extension THMStoryDetailViewModel {
    func deleteStory(id: String, onDeleteSuccess: @escaping (() -> Void)) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.deleteStory(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        onDeleteSuccess()
                    }
                }
                
            } catch {
                
            }
        }
    }
    
    
    func viewStory(id: String) {
        Task {
            do {
                let _ = try await dataManager.viewStory(id: id)
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func likeStory(id: String) {
        Task {
            do {
                let _ = try await dataManager.likeStory(id: id)
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func blockUser(id: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await profileDataManager.blockUser(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
            } catch {
                print(error)
            }
        }
    }
}
