//
//  EditContactViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import CountryPickerView
import SwiftfulRouting
import Combine


class EditContactViewModel: ObservableObject {
    
    var router: AnyRouter
    var currentDialCode: String
    let currentPhoneNumber: String
    var cancellables = Set<AnyCancellable>()
    @Published var selectedCountry: Country? = nil
    @Published var contactFieldText: String = ""
    @Published var showContactModal: Bool = false
    @Published var showVerifyModal: Bool = false
    @Published var toVerifyPhoneNumber: String = ""
    @Published var toVerifyDialCode: String = "+91"
    @Published var otpFieldText: String = ""
    @Published var toVerifyCountry: Country? = nil
    @Published var countDownEnded: Bool = true
    @Published var showLoadingIndicator: Bool = false
    @Published var counter: Int = 60
    let verifyDataManager = MobileVerificationDataManager()
    private var cancellable: Cancellable?
    
    init(router: AnyRouter, currentDialCode: String, currentPhoneNumber: String) {
        self.router             = router
        self.currentDialCode    = currentDialCode
        self.currentPhoneNumber = currentPhoneNumber
        contactFieldText        = currentPhoneNumber
        
        selectedCountry = CountryHelper.shared.getCountry(dialCode: currentDialCode)
        
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $toVerifyCountry
            .sink { [weak self] country in
                guard let self else { return }
                if let country {
                    toVerifyDialCode = country.phoneCode
                }
            }
            .store(in: &cancellables)
    }
    
    
    func setVerificationDetails() {
        toVerifyCountry = selectedCountry
        toVerifyPhoneNumber = contactFieldText
        toVerifyDialCode = currentDialCode
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
}


// MARK: - Networking
extension EditContactViewModel {
    func requestOtp(resend: Bool = false) {
        guard !toVerifyDialCode.isEmpty else { return }
        
        guard toVerifyPhoneNumber.count >= 10 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a valid phone number.")
            return
        }
        
        showLoadingIndicator = true
        
        let parameters: [String: Any] = [
            "dialCode": toVerifyDialCode,
            "phoneNumber": toVerifyPhoneNumber
        ]
        
        Task {
            do {
                let result = try await verifyDataManager.requestOtp(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if !resend {
                            withAnimation(.easeInOut) {
                                showContactModal = false
                                showVerifyModal = true
                                startTimer()
                            }
                        } else {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
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
    
    
    func verifyOtp() {
        guard otpFieldText.count >= 5 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter the full OTP sent to your mobile number.")
            return
        }
        
        showLoadingIndicator = true
        
        let dialCode = toVerifyDialCode
        let phoneNumber = toVerifyPhoneNumber
        
        let parameters: [String: Any] = [
            "dialCode": toVerifyDialCode,
            "phoneNumber": toVerifyPhoneNumber,
            "otp": otpFieldText
        ]
        
        Task {
            do {
                let result = try await verifyDataManager.verifyOtp(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        showVerifyModal = false
                        self.contactFieldText = phoneNumber
                        self.currentDialCode = dialCode
                        self.selectedCountry = toVerifyCountry
//                        checkInData.user?.mobileVerified = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            guard let self else { return }
//                            showCheckoutScreen()
                            router.dismissScreenStack()
                        }
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.data?.message ?? "")
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
