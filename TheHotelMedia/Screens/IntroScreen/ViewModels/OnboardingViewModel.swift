//
//  OnboardingViewModel.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import SwiftfulRouting


final class OnboardingViewModel: ObservableObject {
    
    let localizationManager = LocalizationManager.shared
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    let router: AnyRouter
    @Published var pageCounter: Int = 0
    @Published var animateLogo: Bool = false
    @Published var progress: CGFloat = 25
    
    var headlines: [String] {
        [
            "Find the Best Hotels".localized(localizationManager.language),
            "Rate and Review Hotels".localized(localizationManager.language),
            "Share Your Moments".localized(localizationManager.language),
            "Connect with Friends".localized(localizationManager.language)
        ]
    }
    
    var subheadlines: [String] {
        [
            "Search and discover top-rated hotels around the world.".localized(localizationManager.language),
            "Share your experiences and help others choose the best hotels.".localized(localizationManager.language),
            "Upload photos and videos of your hotel stays.".localized(localizationManager.language),
            "Follow friends and see their hotel reviews and photos.".localized(localizationManager.language)
        ]
    }
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func changePage() {
        if pageCounter == 3 {
//            showSignInScreen()
            hasOnboarded = true
            return
        }
        pageCounter += 1
        progress = CGFloat((pageCounter + 1) * 25)
    }
    
    
    func previousPage() {
        if pageCounter == 0 {
            return
        }
        pageCounter -= 1
        progress = CGFloat((pageCounter + 1) * 25)
    }
    
    
    func showSignInScreen() {
        router.showScreen(.push) { router in
            SignInView(viewModel: SignInViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}
