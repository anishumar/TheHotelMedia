//
//  SelectLanguageViewModel.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class SelectLanguageViewModel: ObservableObject {
    
    var router: AnyRouter
    var initialScreen: Bool
    let dataManager = ProfileDataManager()
    @Published var showLoadingIndicator: Bool = false
    
    init(router: AnyRouter, initialScreen: Bool = false) {
        self.router = router
        self.initialScreen = initialScreen
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            OnboardingView(viewModel: OnboardingViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: -  Networking
extension SelectLanguageViewModel {
    func changeLanguage(to language: SelectedLanguage, completion: (() -> Void)?) {
        let paramater: [String: Any] = [
            "language": language.rawValue.replacingOccurrences(of: "-IN", with: "")
        ]
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.editProfileData(parameters: paramater)
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        completion?()
                        ErrorModalManager.showErrorModal(router: router, errorText: "language_changed_successfully".localized(language))
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
            
        }
    }
}
