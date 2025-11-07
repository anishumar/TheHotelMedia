//
//  PaymentOptionViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting


final class PaymentOptionViewModel: ObservableObject {
    
    let router: AnyRouter
    @Published var selectedOption: PaymentOption? = nil
    @Published var cardNumberText: String = ""
    @Published var expiryDateFieldText: String = ""
    @Published var cvvFieldText: String = ""
    @Published var cardDetailSaved: Bool = false
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            MainTabBarView(viewModel: MainTabBarViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
