//
//  SavedPostViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 15/10/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class SavedPostViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = SavedPostDataManager()
    let postDataManager = PostDataManager()
    @Published var showLoadingIndicator: Bool = false
    @Published var savedPostArray: [PostData] = []
    @Published var pageNo: Int = 1
    @Published var totalPages: Int = 1
    @Published var showPostOptionView: Bool = false
    @Published var postOptionYOffset: CGFloat = 0
    @Published var selectedPostID: String = ""
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    init(router: AnyRouter) {
        self.router = router
        getSavedPost()
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
    
    
    func showEventDetailScreen(id: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: id), onPressedJoin: { [weak self] eventID in
                guard let self else { return }
                
                if var event = savedPostArray.first(where: {$0.id == eventID}) {
                    if let imJoining = event.imJoining {
                        event.imJoining = !imJoining
                    } else {
                        event.imJoining = true
                    }
                    
                    if let index = savedPostArray.firstIndex(where: { $0.id == eventID }) {
                        savedPostArray[index] = event
                    }
                }
                
                
            }, onPressedShare: { [weak self] eventID in
                guard let self else { return }
                
                if var event = savedPostArray.first(where: {$0.id == eventID}) {
                    if let savedByMe = event.savedByMe {
                        event.savedByMe = !savedByMe
                    } else {
                        event.savedByMe = true
                    }
                    
                    if let index = savedPostArray.firstIndex(where: { $0.id == eventID }) {
                        savedPostArray[index] = event
                    }
                }
            })
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
}


// MARK: - Networking
extension SavedPostViewModel  {
    
    func getSavedPost() {
        
        guard pageNo <= totalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getSavedPost(pageNo: pageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            savedPostArray += data
                        }
                        pageNo = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
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
    
    
    func reportPost(id: String) {
        
        Task {
            do {
                let result = try await postDataManager.reportPost(id: id)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status  && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
}
