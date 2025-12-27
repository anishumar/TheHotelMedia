//
//  TermsAndConditionViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting


final class TermsAndConditionViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = TermsConditionDataManager()
    @Published var termsAndConditionsAgreed: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("firstTimeAfterLogin") var firstTimeAfterLogin: Bool = true
    @AppStorage("businessProfileCreatedAt") var businessProfileCreatedAt: String = ""
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func showMainTabBarScreen() {
        router.showScreen(.push) { router in
            MainTabBarView(viewModel: MainTabBarViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSubscriptionScreen() {
        router.showScreen(.push) { router in
            SelectPlanView(viewModel: SelectPlanViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func dismissAllScreens() {
        router.dismissScreenStack()
    }
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorText)
        }
        print(self.errorText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            self.router.dismissModal()
            self.errorText = ""
        }
    }
}


// MARK: - Networking
extension TermsAndConditionViewModel {
    
    func acceptTerms() {
        showLoadingIndicator = true
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        Task {
            do {
                let result = try await dataManager.acceptedTerms()
                
                print(result.message)
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    await MainActor.run {
                        print("DEBUG: Terms checks - isIndividual: \(isIndividual)")
                        if isIndividual {
                            hasLoggedIn = true
                            firstTimeAfterLogin = true
                        } else {
                            print("DEBUG: Business Terms Check - createdAt: \(self.businessProfileCreatedAt)")
                            if Date.isWithinGracePeriod(dateString: self.businessProfileCreatedAt) {
                                print("DEBUG: Grace Period Active -> Going Home")
                                hasLoggedIn = true
                                firstTimeAfterLogin = true
                            } else {
                                print("DEBUG: Grace Period EXPIRED -> Going Subscription")
                                showSubscriptionScreen()
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                print(error)
            }
        }
    }
}
