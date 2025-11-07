//
//  SuggestionScreenViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import Foundation
import Combine
import SwiftfulRouting


class SuggestionScreenViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = SuggestionsDataManager()
    @Published var suggestionsData: [Suggestion] = []
    
    @Published var suggestionsPageNo: Int = 1
    @Published var suggestionsTotalPages: Int = 1
    
    @Published var suggestionListYOffset: [CGFloat] = []
    
    @Published var selectedProfileID: String = ""
    @Published var profileOptionYoffset: CGFloat = 0
    @Published var showProfileOptions: Bool = false
    @Published var showLoadingIndicator: Bool = false
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    init(router: AnyRouter) {
        self.router = router
        getSuggestions()
    }
    
    
    func showUserProfileScreen(id: String) {
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


// MARK: - Networking
extension SuggestionScreenViewModel {
    func getSuggestions() {
        guard suggestionsPageNo <= suggestionsTotalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getSuggestion(pageNo: suggestionsPageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            var yOffsetArray: [CGFloat] = []
                            for _ in data {
                                yOffsetArray.append(0)
                            }
                            suggestionListYOffset += yOffsetArray
                            suggestionsData += data
                        }
                        suggestionsPageNo = result.pageNo ?? 1
                        suggestionsTotalPages = result.totalPages ?? 1
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
