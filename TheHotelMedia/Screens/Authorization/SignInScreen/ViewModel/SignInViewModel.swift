//
//  SignInViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import Combine
import SwiftfulRouting
import FirebaseMessaging


final class SignInViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = SigninManager()
    let deviceIDManager = DeviceIDManager.shared
    var cancellables = Set<AnyCancellable>()
    @Published var emailFieldText: String = ""
    @Published var passwordFieldText: String = ""
    @Published var otherProfessionFieldText: String = ""
    @Published var passwordRightIcon: String? = "EyeSlash"
    @Published var rememberMe: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var isSecure: Bool = true
    @Published var errorText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var isConnected: Bool = false
    @Published var showNotApprovedModal: Bool = false
    @Published var showProfessionModal: Bool = false
    @Published var professions: [Profession] = []
    @Published var selectedProfession: Profession? = nil
    @Published var dropDownOpen: Bool = false
    var latitude: Double = 20.5937
    var longitude: Double = 78.9629
    
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("refreshToken") var refreshToken: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("businessTypeID") var businessTypeID: String = ""
    @AppStorage("businessSubTypeID") var businessSubTypeID: String = ""
    @AppStorage("firstTimeAfterLogin") var firstTimeAfterLogin: Bool = true
    
    @AppStorage("fcmtoken") var fcmtoken: String = ""
    
    @ObservedObject var networkMonitor = NetworkMonitor()
    
    let googleAuthManager = GoogleAuthViewModel()
    let facebookLoginManager = FacebookLoginViewModel()
    let professionManager = IndividualProfessionDataManager()
    
    let localizationManager = LocalizationManager.shared
    var loginResponse: LoginResponse? = nil
    
    init(router: AnyRouter) {
        self.router = router
        addSubcribers()
        getPrefessions()
    }
    
    func addSubcribers() {
        $emailFieldText
            .combineLatest($passwordFieldText)
            .sink { [weak self] (emailText, passwordText) in
                guard let self else { return }
                nextButtonDisabled = !emailText.isEmpty && !passwordText.isEmpty && isValidEmail(emailText) ? false : true
            }
            .store(in: &cancellables)
    }
    
    
    func showMainTabBar() {
        router.showScreen(.push) { router in
            MainTabBarView(viewModel: MainTabBarViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func showSignUpAccountTypeView() {
        router.showScreen(.push) { router in
            SignupAccountTypeView(viewModel: SignupAccountTypeViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSupportScreen() {
        router.showScreen(.push) { router in
            HelpAndSupportView(viewModel: HelpAndSupportViewModel(router: router, enterFields: false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showOtpScreen() {
        router.showScreen(.push) { router in
            OtpView(viewModel: OtpViewModel(router: router, emailID: self.emailFieldText, otpType: "email-verification"))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
    
    
    func setErrorMessage() {
        if emailFieldText.isEmpty {
            errorText = "enter_your_email_address".localized(localizationManager.language)
            return
            
        } else if !isValidEmail(emailFieldText) {
            errorText = "please_enter_a_valid_email_address".localized(localizationManager.language)
            return
            
        } else if passwordFieldText.isEmpty {
            errorText = "please_enter_your_password".localized(localizationManager.language)
            return
        }
        
    }
    
    
    func showTermsAndConditionScreen() {
        router.showScreen(.push) { router in
            TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showIndividualLogoScreen() {
        router.showScreen(.push) { router in
            IndividualSignupLogoView(viewModel: IndividualSignupLogoViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBusinessQuestionsScreen() {
        router.showScreen(.push) { router in
            BusinessQuestionsView(viewModel: BusinessQuestionsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBusinessLogoScreen() {
        router.showScreen(.push) { router in
            BusinessLogoDetailView(viewModel: BusinessLogoDetailViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showBusinessDocumentsScreen() {
        router.showScreen(.push) { router in
            SupportingDocumentsView(viewModel: SupportingDocumentsViewModel(router: router))
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
    
    func showForgotPasswordScreen() {
        router.showScreen(.push) { router in
            EnterEmailScreen(viewModel: EnterEmailScreenViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func signUpWithFacebook() {
        facebookLoginManager.logIn { [weak self] token in
            guard let self else { return }
            facebookSocialLogin(id: token)
            
        } onReceiveError: { [weak self] error in
            guard let self else { return }
            ErrorModalManager.showErrorModal(router: router, errorText: error.localizedDescription)
        }

    }
    
    
    func signUpWithGoogle() {
        googleAuthManager.handleGoogleSignIn { [weak self] idToken in
            guard let self else { return }
            googleSocialLogin(id: idToken)
            
        } onReceiveError: { [weak self] error in
            guard let self else { return }
            ErrorModalManager.showErrorModal(router: router, errorText: error.localizedDescription)
        }
    }
    
    
    func signOutfromGoogle() {
        googleAuthManager.googleSignOut()
    }
    
    /// Retrieves the FCM token, either from AppStorage or synchronously from Firebase Messaging
    private func getFCMToken() -> String {
        // First, check if we already have a stored token
        if !fcmtoken.isEmpty {
            return fcmtoken
        }
        
        // If not, try to get it synchronously from Firebase Messaging
        if let token = Messaging.messaging().fcmToken {
            fcmtoken = token
            return token
        }
        
        // If still unavailable, return empty string (backend will handle validation)
        return ""
    }
    
    /// Waits for FCM token to become available with retries and timeout
    private func waitForFCMToken(maxWaitTime: TimeInterval = 5.0) async -> String {
        // First check if we already have it
        if !fcmtoken.isEmpty {
            return fcmtoken
        }
        
        // Try to get it synchronously first
        if let token = Messaging.messaging().fcmToken {
            fcmtoken = token
            return token
        }
        
        // Wait and retry for FCM token (in case APNS token is still being registered)
        let startTime = Date()
        let retryInterval: TimeInterval = 0.5
        
        while Date().timeIntervalSince(startTime) < maxWaitTime {
            // Check again if token is now available
            if let token = Messaging.messaging().fcmToken, !token.isEmpty {
                fcmtoken = token
                print("✅ FCM Token retrieved after waiting: \(token.prefix(20))...")
                return token
            }
            
            // Wait before next retry
            try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
        }
        
        // If still not available after timeout, try one more time
        if let token = Messaging.messaging().fcmToken, !token.isEmpty {
            fcmtoken = token
            return token
        }
        
        // Check if we're on simulator (where push notifications don't work)
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - push notifications not available. Using deviceID as fallback.")
        return deviceIDManager.getDeviceID()
        #else
        // On real device, return stored token even if empty
        print("⚠️ FCM Token still not available after waiting \(maxWaitTime) seconds")
        return fcmtoken.isEmpty ? deviceIDManager.getDeviceID() : fcmtoken
        #endif
    }
    
}


// MARK: - Networking

extension SignInViewModel {
    
    func login() {
        
        Task {
            do {
//                guard networkMonitor.isConnected else {
//                    errorText = "No internet connection. Please try again."
//                    ErrorModalManager.showErrorModal(router: router, errorText: errorText)
//                    return
//                }
                await MainActor.run {
                    showLoadingIndicator = true
                }
                
                // Wait for FCM token before making API call
                let notificationToken = await waitForFCMToken()
                
                let parameters: [String: Any] = [
                    "email": emailFieldText,
                    "password": passwordFieldText,
                    "deviceID": deviceIDManager.getDeviceID(),
                    "notificationToken": notificationToken,
                    "devicePlatform": "ios",
                    "lat": latitude,
                    "lng": longitude,
                    "language": LocalizationManager.shared.languageString.replacingOccurrences(of: "-IN", with: "")
                ]
                
                print(LocalizationManager.shared.languageString.replacingOccurrences(of: "-IN", with: ""))
                
                let result = try await dataManager.login(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    print(result)
                }
                
                await MainActor.run {
                    let range = 200...204
                    
                    if let status = result.status,
                       let statusCode = result.statusCode {
                        
                        if status && range.contains(statusCode) {
                            handleLoginResponse(response: result)
                        } else {
                            if let data = result.data {
                                if let isVerified = data.isVerified, !isVerified && statusCode == 403 {
                                    handleLoginResponse(response: result)
                                } else if let hasSubscription = data.hasSubscription, !hasSubscription && statusCode == 403 {
                                    handleLoginResponse(response: result)
                                } else if let isApproved = data.isApproved,
                                          !isApproved {
                                    errorText = result.message ?? ""
                                    showNotApprovedModal = true
                                    
                                } else if let message = result.message {
                                    if message.contains("deleted") || message.contains("inactive") {
                                        errorText = message
                                        showNotApprovedModal = true
                                    } else {
                                        ErrorModalManager.showErrorModal(router: router, errorText: message)
                                    }
                                }
                            } else if let message = result.message {
                                if message.contains("deleted") || message.contains("inactive") {
                                    errorText = message
                                    showNotApprovedModal = true
                                } else {
                                    ErrorModalManager.showErrorModal(router: router, errorText: message)
                                }
                            }
                        }
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
    
    
    func googleSocialLogin(id: String) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                // Wait for FCM token before making API call
                let notificationToken = await waitForFCMToken()
        
        var parameters: [String: Any] = [
            "socialType": "google",
            "token": id,
            "deviceID": deviceIDManager.getDeviceID(),
            "devicePlatform": "ios",
                    "notificationToken": notificationToken,
            "lat": latitude,
            "lng": longitude,
            "language": LocalizationManager.shared.language.rawValue.replacingOccurrences(of: "-IN", with: "")
        ]
        
                let result = try await dataManager.socialLogin(parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if let status = result.status,
                       let statusCode = result.statusCode {
                        
                        if status && range.contains(statusCode) {
                            handleLoginResponse(response: result)
                        } else {
                            let errorMessage = result.message ?? "Login failed. Please try again."
                            ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: "Invalid response from server")
                    }
                    
                    showLoadingIndicator = false
                }
            } catch {
                print("Google Social Login Error: \(error)")
                await MainActor.run {
                    showLoadingIndicator = false
                    var errorMessage = "Login failed. Please try again."
                    if let networkError = error as? NetworkError {
                        errorMessage = networkError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                }
            }
        }
    }
    
    
    func facebookSocialLogin(id: String) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                // Wait for FCM token before making API call
                let notificationToken = await waitForFCMToken()
        
        let parameters: [String: Any] = [
            "socialType": "facebook",
            "token": id,
            "deviceID": deviceIDManager.getDeviceID(),
            "devicePlatform": "ios",
                    "notificationToken": notificationToken,
            "lat": latitude,
            "lng": longitude,
            "language": LocalizationManager.shared.language.rawValue.replacingOccurrences(of: "-IN", with: "")
        ]
        
                let result = try await dataManager.socialLogin(parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if let status = result.status,
                       let statusCode = result.statusCode {
                        
                        if status && range.contains(statusCode) {
                            handleLoginResponse(response: result)
                        } else {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message ?? "")
                        }
                    }
                    
                    showLoadingIndicator = false
                }
            } catch {
                print(error)
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func appleSocialLogin(idToken: String, name: String? = nil, email: String? = nil) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                // Wait for FCM token before making API call
                let notificationToken = await waitForFCMToken()
        
        var parameters: [String: Any] = [
            "socialType": "apple",
            "token": idToken,
            "deviceID": deviceIDManager.getDeviceID(),
            "devicePlatform": "ios",
                    "notificationToken": notificationToken,
            "lat": latitude,
            "lng": longitude,
            "language": LocalizationManager.shared.language.rawValue.replacingOccurrences(of: "-IN", with: "")
        ]
        
        if let name, !name.isEmpty {
            parameters.updateValue(name, forKey: "name")
        }
        
        if let email, !email.isEmpty {
            parameters.updateValue(email, forKey: "email")
        }
        
                let result = try await dataManager.socialLogin(parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if let status = result.status,
                       let statusCode = result.statusCode {
                        
                        if status && range.contains(statusCode) {
                            handleLoginResponse(response: result)
                        } else {
                            let errorMessage = result.message ?? "Login failed. Please try again."
                            ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: "Invalid response from server")
                    }
                    
                    showLoadingIndicator = false
                }
            } catch {
                print("Apple Social Login Error: \(error)")
                await MainActor.run {
                    showLoadingIndicator = false
                    var errorMessage = "Login failed. Please try again."
                    if let networkError = error as? NetworkError {
                        errorMessage = networkError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                }
            }
        }
    }
    
    
    func handleLoginResponse(response: LoginResponse) {
        loginResponse = response
        
        guard let _ = response.status,
              let _ = response.statusCode,
              let message = response.message
               else {
            
            return
        }
        
        
        guard let data = response.data else {
            errorText = message
            ErrorModalManager.showErrorModal(router: router, errorText: errorText)
            return
        }
        
        guard let isVerified = data.isVerified,
              let hasProfilePicture = data.hasProfilePicture,
              let accountType = data.accountType,
              let acceptedTerms = data.acceptedTerms else {
            
            errorText = message
            ErrorModalManager.showErrorModal(router: router, errorText: errorText)
            return
        }
        
        self.isIndividual = accountType == "individual"
        
        if accountType == "individual" {
            guard isVerified else {
                showOtpScreen()
                return
            }
            
            guard let accessToken = data.accessToken,
                  let refreshToken = data.refreshToken else {
                return
            }
            
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            
            if let profession = data.profession, profession.isNotEmpty {
                guard hasProfilePicture else {
                    showIndividualLogoScreen()
                    return
                }
                
                
                guard acceptedTerms else {
                    showTermsAndConditionScreen()
                    return
                }
                
                hasLoggedIn = true
                firstTimeAfterLogin = true
                
            } else {
                showProfessionModal = true
                
            }
//            guard hasProfilePicture else {
//                showIndividualLogoScreen()
//                return
//            }
//            
//            
//            guard acceptedTerms else {
//                showTermsAndConditionScreen()
//                return
//            }
//            
//            hasLoggedIn = true
//            firstTimeAfterLogin = true
            
        } else {
            guard isVerified else {
                showOtpScreen()
                return
            }
            
            guard let accessToken = data.accessToken else {
                return
            }
            
            self.accessToken = accessToken
            
            guard let hasAmenities = data.hasAmenities else {
                return
            }
            
            guard let businessProfileRef = data.businessProfileRef,
               let businessTypeID = businessProfileRef.businessTypeID,
               let businessSubTypeID = businessProfileRef.businessSubTypeID else {
                return
            }
            
            self.businessTypeID = businessTypeID
            self.businessSubTypeID = businessSubTypeID
            
            guard hasAmenities else {
                showBusinessQuestionsScreen()
                return
            }
            
            guard hasProfilePicture else {
                showBusinessLogoScreen()
                return
            }
            
            guard let isDocumentUploaded = data.isDocumentUploaded else { return }
            
            guard isDocumentUploaded else {
                showBusinessDocumentsScreen()
                return
            }
            
            guard acceptedTerms else {
                showTermsAndConditionScreen()
                return
            }
            
            guard let hasSubscription = data.hasSubscription else {
                return
            }
            
            guard hasSubscription else {
                showSubscriptionScreen()
                return
            }
            
            guard let isApproved = data.isApproved else {
                return
            }
            
            if isApproved {
                
                if let refreshToken = data.refreshToken {
                    self.refreshToken = refreshToken
                }
                
                hasLoggedIn = true
                firstTimeAfterLogin = true
            }
        }
    }
    
    
    func getPrefessions() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await professionManager.getProfessions()
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            professions = data
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Invalid server response.")
                }
            }
        }
    }
    
    
    func updateProfession(profession: String) {
        showProfessionModal = false
        showLoadingIndicator = true
        Task {
            do {
                let result = try await professionManager.updateProfession(profession: profession)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        if let hasProfilePicture = loginResponse?.data?.hasProfilePicture,
                           let acceptedTerms = loginResponse?.data?.acceptedTerms {
                            guard hasProfilePicture else {
                                showIndividualLogoScreen()
                                return
                            }
                            
                            
                            guard acceptedTerms else {
                                showTermsAndConditionScreen()
                                return
                            }
                            
                            hasLoggedIn = true
                            firstTimeAfterLogin = true
                        }
                           
                            
                    } else {
                        accessToken = ""
                        refreshToken = ""
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    accessToken = ""
                    refreshToken = ""
                }
            }
        }
    }
}
