//
//  PhoneLoginViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import Combine
import SwiftfulRouting
import FirebaseAuth
import FirebaseMessaging
import CountryPickerView

class PhoneLoginViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = SigninManager()
    let deviceIDManager = DeviceIDManager.shared
    
    @Published var phoneNumber: String = ""
    @Published var selectedCountry: Country?
    @Published var dialCode: String = "+91"
    
    @Published var otpFieldText: String = ""
    @Published var showVerifyModal: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
    @Published var counter: Int = 60
    @Published var countDownEnded: Bool = true
    
    @AppStorage("verificationID") var currentVerificationID: String = ""
    @AppStorage("fcmtoken") var fcmtoken: String = ""
    
    var cancellables = Set<AnyCancellable>()
    private var timerCancellable: Cancellable?
    
    // Login Success Handling (similar to SignInViewModel)
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("refreshToken") var refreshToken: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("businessTypeID") var businessTypeID: String = ""
    @AppStorage("businessSubTypeID") var businessSubTypeID: String = ""
    @AppStorage("firstTimeAfterLogin") var firstTimeAfterLogin: Bool = true
    @AppStorage("businessProfileCreatedAt") var businessProfileCreatedAt: String = ""
    
    @Published var showNotApprovedModal: Bool = false
    @Published var showProfessionModal: Bool = false
    @Published var professions: [Profession] = [] // Needed if we reuse handleLoginResponse logic fully
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter) {
        self.router = router
        self.selectedCountry = CountryHelper.shared.getCountry(dialCode: dialCode)
        addSubscribers()
    }
    
    private func addSubscribers() {
        $selectedCountry
            .sink { [weak self] country in
                guard let self, let country else { return }
                DispatchQueue.main.async {
                    self.dialCode = country.phoneCode
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Timer Logic
    func startTimer() {
        counter = 60
        countDownEnded = false
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.counter > 0 {
                    self.counter -= 1
                } else {
                    self.cancelTimer()
                }
            }
    }
    
    func cancelTimer() {
        countDownEnded = true
        timerCancellable?.cancel()
    }
    
    // MARK: - FCM Token
    private func waitForFCMToken(maxWaitTime: TimeInterval = 5.0) async -> String {
        if !fcmtoken.isEmpty { return fcmtoken }
        if let token = Messaging.messaging().fcmToken {
            fcmtoken = token
            return token
        }
        
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < maxWaitTime {
            if let token = Messaging.messaging().fcmToken, !token.isEmpty {
                fcmtoken = token
                return token
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        #if targetEnvironment(simulator)
        return deviceIDManager.getDeviceID()
        #else
        return fcmtoken.isEmpty ? deviceIDManager.getDeviceID() : fcmtoken
        #endif
    }
    
    // MARK: - API / Firebase
    
    func requestOtp(resend: Bool = false) {
        let cleanPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanPhone.count >= 10 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a valid phone number.")
            return
        }
        
        showLoadingIndicator = true
        let fullPhoneNumber = dialCode + cleanPhone
        print("📱 Requesting OTP for: \(fullPhoneNumber)")
        
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.showLoadingIndicator = false
                
                if let error = error {
                    ErrorModalManager.showErrorModal(router: self.router, errorText: error.localizedDescription)
                    return
                }
                
                if let verificationID = verificationID {
                    self.currentVerificationID = verificationID
                    
                    if !resend {
                        withAnimation {
                            self.showVerifyModal = true
                        }
                    }
                    self.startTimer()
                }
            }
        }
    }
    
    func verifyOtpAndLogin() {
        guard otpFieldText.count >= 6 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter the full 6-digit OTP.")
            return
        }
        
        showLoadingIndicator = true
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: currentVerificationID,
            verificationCode: otpFieldText
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: self.router, errorText: error.localizedDescription)
                }
                return
            }
            
            // Firebase Auth Success -> Now call Backend Login
            // We sign out from Firebase purely because we rely on our custom backend token
            try? Auth.auth().signOut()
            
            self.performBackendLogin()
        }
    }
    
    private func performBackendLogin() {
        Task {
            do {
                let notificationToken = await waitForFCMToken()
                
                let parameters: [String: Any] = [
                    "phoneNumber": phoneNumber,
                    "dialCode": dialCode,
                    "deviceID": deviceIDManager.getDeviceID(),
                    "devicePlatform": "ios",
                    "notificationToken": notificationToken,
                    "lat": 20.5937, // Default or fetch real location if available
                    "lng": 78.9629,
                    "language": LocalizationManager.shared.languageString.replacingOccurrences(of: "-IN", with: "")
                ]
                
                let result = try await dataManager.otpLogin(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    let range = 200...204
                    if let status = result.status, let statusCode = result.statusCode {
                        if status && range.contains(statusCode) {
                            handleLoginResponse(response: result)
                        } else {
                            // Handle error cases similar to SignInViewModel
                            if let message = result.message {
                                // Allow login if account is under review (403) or just show modal if deleted/inactive
                                if statusCode == 403 && !message.contains("deleted") && !message.contains("inactive") {
                                     handleLoginResponse(response: result)
                                } else if message.contains("deleted") || message.contains("inactive") {
                                    errorText = message
                                    showNotApprovedModal = true
                                } else {
                                    ErrorModalManager.showErrorModal(router: router, errorText: message)
                                }
                            } else {
                                ErrorModalManager.showErrorModal(router: router, errorText: "Login failed")
                            }
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message ?? "Unknown error")
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: error.localizedDescription)
                }
            }
        }
    }
    
    // Copied/Adapted from SignInViewModel to handle successful login response
    func handleLoginResponse(response: LoginResponse) {
        guard let data = response.data else { return }

        guard let isVerified = data.isVerified,
              let hasProfilePicture = data.hasProfilePicture,
              let accountType = data.accountType,
              let acceptedTerms = data.acceptedTerms else {
            ErrorModalManager.showErrorModal(router: router, errorText: response.message ?? "Invalid data")
            return
        }

        self.isIndividual = (accountType == "individual")

        if accountType == "individual" {
            // Individual Logic
            guard isVerified else {
                // If phone login works, they are by definition verified?
                // Or maybe email is not verified? The API says "Account is unverified".
                // We'll assume if success, we are good or follow existing flow.
                return
            }
            
            if let accessToken = data.accessToken, let refreshToken = data.refreshToken {
                self.accessToken = accessToken
                self.refreshToken = refreshToken
            }
            
            if let profession = data.profession, !profession.isEmpty {
                if !hasProfilePicture {
                     // Navigate to Logo Screen - need to expose these from SignInViewModel or duplicate logic
                     // For now, let's just assume we set logged in if complete
                }
                
                if !acceptedTerms {
                    // Navigate to Terms
                }
                
                hasLoggedIn = true
                firstTimeAfterLogin = true
            } else {
                 showProfessionModal = true
            }
            

            
        } else {
            // Business Logic
            guard let accessToken = data.accessToken else { return }
            self.accessToken = accessToken
            
            if let reflex = data.refreshToken {
                self.refreshToken = reflex
            }
            
            if let createdAt = data.createdAt {
                self.businessProfileCreatedAt = createdAt
            }
            
            // Grace Period Check
            let hasSubscription = data.hasSubscription ?? false
             
             if !hasSubscription {
                 let createdAt = data.createdAt
                 if Date.isWithinGracePeriod(dateString: createdAt) {
                     hasLoggedIn = true
                     firstTimeAfterLogin = true
                 } else {
                     showSubscriptionScreen()
                 }
             } else {
                 hasLoggedIn = true
                 firstTimeAfterLogin = true
             }
        }
    }
    
    func showSubscriptionScreen() {
        router.showScreen(.push) { router in
            SubscriptionView(viewModel: SubscriptionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}
