//
//  ForgotPasswordViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation
import SwiftfulRouting
import Combine


class EnterEmailScreenViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let dataManager = OtpForgotPasswordManager()
    @Published var emailFieldText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var errorText: String = ""
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $emailFieldText
            .sink { [weak self] string in
                guard let self else { return }
                nextButtonDisabled = !isValidEmail(string)
            }
            .store(in: &cancellables)
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    func showOtpScreen() {
        router.showScreen(.push) { router in
            OtpView(viewModel: OtpViewModel(router: router, emailID: self.emailFieldText, otpType: "forgot-password"))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
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
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
}


// MARK: - Networking
extension EnterEmailScreenViewModel {
    func forgotPassword() {
        
        let parameters: [String: Any] = [
            "email" : emailFieldText
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getOtpForgotPassword(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        showOtpScreen()
                    } else {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
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
