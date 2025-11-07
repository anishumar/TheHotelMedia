//
//  SignupAccountTypeViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import Foundation
import Combine
import SwiftfulRouting

final class SignupAccountTypeViewModel: ObservableObject {
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    @Published var accountType: AccountType? = nil
    @Published var nextButtonDisabled: Bool = true
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    func addSubscribers() {
        $accountType
            .sink { [weak self] accountType in
                guard let self else { return }
                
                nextButtonDisabled = accountType != nil ? false : true
            }
            .store(in: &cancellables)
    }
    
    
    func showNextScreen() {
        guard let accountType else { return }
        
        switch accountType {
        case .individual:
            router.showScreen(.push) { router in
                IndividualSignupView(viewModel: IndividualSignupViewModel(router: router))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        case .business:
            router.showScreen(.push) { router in
                SelectBusinessTypeView(viewModel: SelectBusinessTypeViewModel(router: router))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    func showBusinessSignupScreen() {
        router.showScreen(.push) { router in
            SelectBusinessTypeView(viewModel: SelectBusinessTypeViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showIndividualSignupScreen() {
        router.showScreen(.push) { router in
            IndividualSignupView(viewModel: IndividualSignupViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
}
