//
//  ConfirmEmailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine

class ConfirmEmailViewModel: ObservableObject {
    
    var router: AnyRouter
    let email: String
    var cancellable: AnyCancellable?
    var cancellables = Set<AnyCancellable>()
    let dataManager = OtpForgotPasswordManager()
    let otpDataManager = OtpDataManager()
    @Published var counter: Int = 60
    @Published var nextButtonDisabled: Bool = true
    @Published var countDownEnded: Bool = true
    @Published var otpFieldText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
    
    
    init(router: AnyRouter, email: String) {
        self.router = router
        self.email = email
        addSubscribers()
        forgotPassword()
        startTimer()
    }
    
    
    func addSubscribers() {
        $otpFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.count == 5 {
                    nextButtonDisabled = false
                } else {
                    nextButtonDisabled = true
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func startTimer() {
        counter = 60
        
        countDownEnded = false
        
        let countDownTimer = Timer.publish(every: 1.0, on: .main, in: .default).autoconnect()
        
        cancellable = countDownTimer
            .sink{ [weak self] _ in
                guard let self else { return }
                
                guard counter > 0 else {
                    cancelTimer()
                    return
                }
                
                self.counter -= 1
            }
    }
    
    
    func cancelTimer() {
        countDownEnded = true
        cancellable?.cancel()
    }
    
    
    func showChangePasswordScreen(email: String, resetToken: String) {
        router.showScreen(.push) { router in
            ChangePasswordView(viewModel: ChangePasswordViewModel(router: router, email: email , resetToken: resetToken))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension ConfirmEmailViewModel {
    func forgotPassword() {
        
        let parameters: [String: Any] = [
            "email" : email
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getOtpForgotPassword(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        
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
    
    func verifyForgotPasswordOtp() {
        showLoadingIndicator = true
        
        let parameters: [String: Any] = [
            "email": email,
            "otp": otpFieldText
        ]
        
        Task {
            do {
                let result = try await otpDataManager.verifyForgotPasswordOtp(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if let data = result.data {
                            guard let email = data.email,
                                  let resetToken = data.resetToken else {
                                return
                            }
                            showChangePasswordScreen(email: email, resetToken: resetToken)
                        }
                    } else {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
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
    
    
    func resendOtp() {
        let parameters: [String: Any] = [
            "email": email,
            "type": "forgot-password"
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let response = try await otpDataManager.resendOtp(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if let message = response.message {
                        errorText = message
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
