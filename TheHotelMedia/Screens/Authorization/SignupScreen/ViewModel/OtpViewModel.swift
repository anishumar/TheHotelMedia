//
//  OtpViewModel.swift
//  HotelMedia
//
//  Created by MAC on 14/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class OtpViewModel: ObservableObject {
    
    private var cancellable: Cancellable?
    let dataManager = OtpDataManager()
    let deviceIDManager = DeviceIDManager.shared
    var router: AnyRouter
    let emailID: String
    let otpType: String
    @Published var otpFieldText: String = ""
    @Published var countDownEnded: Bool = true
    @Published var counter: Int = 60
    @Published var nextButtonDisabled: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("refreshToken") var refreshToken: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    
    init(router: AnyRouter, emailID: String, otpType: String) {
        self.router = router
        self.emailID = emailID
        self.otpType = otpType
        startTimer()
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
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showIndividualLogoScreen() {
        router.showScreen(.push) { router in
            IndividualSignupLogoView(viewModel: IndividualSignupLogoViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBusinessQuestionsView() {
        router.showScreen(.push) { router in
            BusinessQuestionsView(viewModel: BusinessQuestionsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showTermsAndConditionScreen() {
        router.showScreen(.push) { router in
            TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showChangePasswordScreen(email: String, resetToken: String) {
        router.showScreen(.push) { router in
            ChangePasswordScreen(viewModel: ChangePasswordScreenViewModel(router: router, email: email , resetToken: resetToken))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
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

extension OtpViewModel {
    
    func verifyOtp() {
        
        let parameters: [String: Any] = [
            "email": emailID,
            "otp": otpFieldText,
            "deviceID": deviceIDManager.getDeviceID(),
            "notificationToken": deviceIDManager.getDeviceID(),
            "devicePlatform": "ios"
        ]
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let response = try await dataManager.verifyOtp(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    print(response)
                    handleResponse(response: response)
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Internal server error!")
                    print(error)
                }
            }
        }
    }
    
    
    func verifyForgotPasswordOtp() {
        showLoadingIndicator = true
        
        let parameters: [String: Any] = [
            "email": emailID,
            "otp": otpFieldText
        ]
        
        Task {
            do {
                let result = try await dataManager.verifyForgotPasswordOtp(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            guard let email = data.email,
                                  let resetToken = data.resetToken else {
                                return
                            }
                            
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                                guard let self else { return }
                                showChangePasswordScreen(email: email, resetToken: resetToken)
                            }
                            
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
            "email": emailID,
            "type": otpType
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let response = try await dataManager.resendOtp(parameters: parameters)
                
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
    
    
    func handleResponse(response: OtpVerifyResponse) {
        
        guard let status = response.status,
              let statusCode = response.statusCode,
              let message = response.message else {
            return
        }
        
        let range = 200...204
        if status && range.contains(statusCode) {
            guard let data = response.data,
                  let accessToken = data.accessToken,
                  let accountType = data.accountType else {
                return
            }
            
            self.accessToken = accessToken
            self.isIndividual = accountType == "individual"
            
            ErrorModalManager.showErrorModal(router: router, errorText: message)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self else { return }
                if isIndividual {
                    
                    if let refreshToken = data.refreshToken {
                        self.refreshToken = refreshToken
                    }
                    showIndividualLogoScreen()
                    
                } else {
                    showBusinessQuestionsView()
                }
            }
        } else {
            ErrorModalManager.showErrorModal(router: router, errorText: message)
        }
    }
}
