//
//  IndividualSignupViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import CountryPickerView
import PhoneNumberKit


final class IndividualSignupViewModel: ObservableObject {
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let manager = IndividualSignupManager()
    let professionManager = IndividualProfessionDataManager()
    @Published var showLoadingIndicator: Bool = false
    @Published var nameFieldText: String = ""
    @Published var emailFieldText: String = ""
    @Published var otherProfessionFieldText: String = ""
    @Published var dialCode: String = "+91"
    @Published var passwordFieldText: String = ""
    @Published var possibleLength: Int = 10
    @Published var contactFieldText: String = ""
    @Published var passwordRightIcon: String? = "EyeSlash"
    @Published var isSecure: Bool = true
    @Published var nextButtonDisabled: Bool = false
    @Published var selectedCountry: Country?
    @Published var errorMessage: String = ""
    @Published var professions: [Profession] = []
    @Published var selectedProfession: Profession? = nil
    @Published var dropDownOpen: Bool = false
    var latitude: Double = 20.5937
    var longitude: Double = 78.9629
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $nameFieldText
            .combineLatest($emailFieldText, $passwordFieldText, $contactFieldText)
            .map { [weak self] (name, email, password, contact) -> Bool in
                guard let self else { return false }
                return name.count > 2 && !email.isEmpty && self.isValidEmail(email) && !password.isEmpty && isPasswordValid(password) && contact.count == possibleLength && name.rangeOfCharacter(from: .decimalDigits) == nil
            }
            .combineLatest($selectedProfession, $otherProfessionFieldText)
            .map({ [weak self] (bool, profession, otherProfession) -> Bool in
                guard let self else { return false }
                if bool, let profession = profession {
                    if let name = profession.name {
                        if name.localized(localizationManager.language) == "Others".localized(localizationManager.language) {
                            if otherProfession.isEmpty {
                                return false
                                
                            } else {
                                return true
                                
                            }
                        } else {
                            return true
                        }
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            })
            .sink { [weak self] (bool) in
                guard let self else { return }
                nextButtonDisabled = !bool
            }
            .store(in: &cancellables)
        
        $selectedCountry
            .sink { [weak self] country in
                guard let self else { return }
                if let country {
                    dialCode = country.phoneCode
                    let symbol = country.code
                    possibleLength = getPossibleLengths(symbol: symbol)
                    contactFieldText = contactFieldText
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            OtpView(viewModel: OtpViewModel(router: router, emailID: self.emailFieldText, otpType: "email-verification"))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    private func isValidContactNo(number: String) -> Bool {
        return true
    }
    
    
    private func getPossibleLengths(symbol: String) -> Int {
        let phoneNumberUtility = PhoneNumberUtility()
        if let phoneNo = phoneNumberUtility.metadata(for: symbol)?.mobile?.exampleNumber {
            let count = phoneNo.count
            return count
        }
        
        return 10
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
            
        } else if passwordFieldText.isEmpty {
            errorMessage = "enter_your_password".localized(localizationManager.language)
            return
            
        } else if let message = getPasswordValidationMessage(passwordFieldText) {
            errorMessage = message
            return
            
        } else if contactFieldText.count != possibleLength {
            errorMessage = "please_enter_a_valid_contact_number".localized(localizationManager.language)
            return
        } else if let selectedProfession {
            if let name = selectedProfession.name {
                if name.localized(localizationManager.language) == "Others".localized(localizationManager.language), otherProfessionFieldText.isEmpty {
                    errorMessage = "Please enter a profession name.".localized(localizationManager.language)
                }
            } else {
                errorMessage = "Please select a profession.".localized(localizationManager.language)
            }
        } else if selectedProfession == nil {
            errorMessage = "Please select a profession.".localized(localizationManager.language)
        }
    }
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
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
            return "Password must contain at least one lowercase letter.".localized(localizationManager.language)
        } else if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_number".localized(localizationManager.language)
        } else if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) == nil {
            return "password_must_contain_at_least_one_special_character".localized(localizationManager.language)
        }
        return nil
    }
}

// Networking Code.
extension IndividualSignupViewModel {
    
    
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
    
    
    func createNewAccount() async {
        
        var profession = "Others"
        
        if let selectedProfession {
            if let name = selectedProfession.name {
                if name == "Others" {
                    profession = otherProfessionFieldText
                } else {
                    profession = name
                }
            }
        }
        
        let parameters: [String: Any] = [
            "accountType": "individual",
            "email": emailFieldText,
            "dialCode": dialCode,
            "phoneNumber": contactFieldText,
            "name": nameFieldText,
            "password": passwordFieldText,
            "profession": profession,
            "lat": latitude,
            "lng": longitude
        ]
        
        do {
            await MainActor.run {
                showLoadingIndicator = true
            }
            let response = try await manager.createAccount(parameters: parameters)
            await MainActor.run {
                showLoadingIndicator = false
            }
            
            if response.statusCode == 200 || response.statusCode == 201 {
                await MainActor.run {
                    ErrorModalManager.showErrorModal(router: router, errorText: response.message ?? "")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        guard let self else { return }
                        showNextScreen()
                    }
                }
                
            } else {
                await MainActor.run {
                    errorMessage = response.message ?? ""
                    ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
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
