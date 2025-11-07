//
//  ManagerDetailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting
import CountryPickerView
import Combine
import PhoneNumberKit


final class ManagerDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let businessData: BusinessData
    let dataManager = BusinessSignupManager()
    var cancellables = Set<AnyCancellable>()
    @Published var nameFieldText: String = ""
    @Published var emailFieldText: String = ""
    @Published var passwordFieldText: String = ""
    @Published var possibleLength: Int = 10
    @Published var contactFieldText: String = ""
    @Published var passwordRightIcon: String? = "EyeSlash"
    @Published var isSecure: Bool = true
    @Published var nextButtonDisabled: Bool = false
    @Published var selectedCountry: Country?
    @Published var errorMessage: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var dialCode: String = "+91"
    
    @AppStorage("businessTypeID") var businessTypeID: String = ""
    @AppStorage("businessSubTypeID") var businessSubTypeID: String = ""
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter, businessData: BusinessData) {
        self.router = router
        self.businessData = businessData
    }
    
    
    func addSubscribers() {
        $nameFieldText
            .combineLatest($emailFieldText, $passwordFieldText, $contactFieldText)
            .map({ [weak self] (nameText, emailText, passwordText, contactText) -> (Bool) in
                guard let self else { return false }
                return nameText.count > 2 && isValidEmail(emailText) && contactText.count == possibleLength && !passwordText.isEmpty && isPasswordValid(passwordText) && nameText.rangeOfCharacter(from: .decimalDigits) == nil
            })
            .sink { [weak self] bool in
                guard let self else { return }
                
                nextButtonDisabled = !bool
            }
            .store(in: &cancellables)
        
        
        $selectedCountry
            .sink { [weak self] country in
                guard let self else { return }
                if let country {
                    let symbol = country.code
                    possibleLength = getPossibleLengths(symbol: symbol)
                    dialCode = country.phoneCode
                    contactFieldText = contactFieldText
                }
            }
            .store(in: &cancellables)
            
    }
    
    
    func showNextScreen() {
        
        businessTypeID = businessData.businessType ?? ""
        businessSubTypeID = businessData.businessSubType ?? ""
        
        router.showScreen(.push) { router in
            OtpView(viewModel: OtpViewModel(router: router, emailID: self.emailFieldText, otpType: "email-verification"))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    private func getPossibleLengths(symbol: String) -> Int {
        let phoneNumberUtility = PhoneNumberUtility()
        if let phoneNo = phoneNumberUtility.metadata(for: symbol)?.mobile?.exampleNumber {
            let count = phoneNo.count
            return count
        }
        
        return 10
    }
    
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorMessage)
        }
        print(self.errorMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            self.router.dismissModal()
            self.errorMessage = ""
        }
    }
    
    
    func setErrorMessage() {
        if nameFieldText.isEmpty {
            errorMessage = "enter_your_full_name".localized(localizationManager.language)
            return
            
        } else if nameFieldText.rangeOfCharacter(from: .decimalDigits) != nil {
            errorMessage = "your_name_cannot_contain_numeric_values".localized(localizationManager.language)
            return
            
        } else if emailFieldText.isEmpty {
            errorMessage = "enter_your_email_address".localized(localizationManager.language)
            return
            
        } else if !emailFieldText.isEmpty && !isValidEmail(emailFieldText) {
            errorMessage = "please_enter_a_valid_email_address".localized(localizationManager.language)
            return
            
        }  else if passwordFieldText.isEmpty {
            errorMessage = "enter_your_password".localized(localizationManager.language)
            return
            
        } else if let message = getPasswordValidationMessage(passwordFieldText) {
            errorMessage = message
            return
            
        } else if contactFieldText.count != possibleLength {
            errorMessage = "please_enter_a_valid_contact_number".localized(localizationManager.language)
            return
        }
    }
    
    
    func isPasswordValid(_ password: String) -> Bool {
        return getPasswordValidationMessage(password) == nil
    }

    func getPasswordValidationMessage(_ password: String) -> String? {
        if password.isEmpty {
            return "enter_your_password".localized(localizationManager.language)
        } else if password.count < 8 {
            return "password_must_be_at_least_8_characters".localized(localizationManager.language)
        } else if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_uppercase_letter".localized(localizationManager.language)
        } else if password.range(of: "[a-z]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_lowercase_letter".localized(localizationManager.language)
        } else if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_number".localized(localizationManager.language)
        } else if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_special_character".localized(localizationManager.language)
        }
        return nil
    }
    
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func getFullBusinessData() -> BusinessData {
        var businessData = businessData
        
        businessData.name = nameFieldText
        businessData.email = emailFieldText
        businessData.dialCode = dialCode
        businessData.phoneNumber = contactFieldText
        businessData.password = passwordFieldText
        
        return businessData
    }
}


// MARK: - Networking
extension ManagerDetailViewModel {
    
    func businessSignup() {
        
        let businessData = getFullBusinessData()
        
        var zipCode: String = ""
        
        if let code = businessData.zipCode, !code.isEmpty {
            zipCode = code
        } else {
            zipCode = "140306"
        }
        
        let parameters: [String: Any] = [
            "email": businessData.email ?? "",
            "name": businessData.name ?? "",
            "accountType": businessData.accountType ?? "",
            "dialCode": businessData.dialCode ?? "",
            "phoneNumber": businessData.phoneNumber ?? "",
            "password": businessData.password ?? "",
            "businessName": businessData.businessName ?? "",
            "businessEmail": businessData.businessEmail ?? "",
            "businessPhoneNumber": businessData.businessPhoneNumber ?? "",
            "businessDialCode": businessData.businessDialCode ?? "",
            "businessType": businessData.businessType ?? "",
            "businessSubType": businessData.businessSubType ?? "",
            "bio": businessData.businessDescription ?? "",
            "businessWebsite": businessData.businessWebsite ?? "",
            "gstn": businessData.gstn ?? "",
            "street": businessData.street ?? "",
            "city": businessData.city ?? "",
            "state": businessData.state ?? "",
            "zipCode": zipCode,
            "country": businessData.country ?? "",
            "lng": businessData.lng ?? "",
            "lat": businessData.lat ?? "",
            "placeID": businessData.placeID ?? ""
        ]
        
//        guard networkMonitor.isConnected else {
//            errorMessage = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.businessSignup(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            showNextScreen()
                        }
                         
                    } else {
                        errorMessage = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                    }
                }
                
                print(result.message)
                
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
}
