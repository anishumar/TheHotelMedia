//
//  ChangePasswordViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class ChangePasswordViewModel: ObservableObject {
    
    var router: AnyRouter
    var email: String
    var resetToken: String
    let dataManager = ChangePasswordManager()
    var cancellables = Set<AnyCancellable>()
    @Published var passwordFieldText: String = ""
    @Published var isSecure: Bool = true
    @Published var rightIcon: String? = "EyeSlash"
    @Published var passwordFieldText2: String = ""
    @Published var isSecure2: Bool = true
    @Published var rightIcon2: String? = "EyeSlash"
    @Published var showLoadingIndicator: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var errorText: String = ""
    
    init(router: AnyRouter, email: String, resetToken: String) {
        self.router = router
        self.email = email
        self.resetToken = resetToken
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $passwordFieldText2
            .combineLatest($passwordFieldText)
            .debounce(for: 0.5 , scheduler: RunLoop.main)
            .sink { [weak self] (text2, text1) in
                guard let self else { return }
                
                if !text1.isEmpty && text1 == text2 {
                    nextButtonDisabled = false
                } else {
                    nextButtonDisabled = true
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissAllScreens() {
        router.dismissScreenStack()
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showErrorMessage() {
        if passwordFieldText.isEmpty {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a new password.")
        } else if passwordFieldText2.isEmpty {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please confirm the password.")
        } else if passwordFieldText != passwordFieldText2 {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter the same password in both the fields.")
        }
    }
}


// MARK: - Networking

extension ChangePasswordViewModel {
    func changePassword() {
        let parameters: [String: Any] = [
            "password" : passwordFieldText,
            "resetToken" : resetToken,
            "email" : email
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.changePassword(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            dismissAllScreens()
                        }
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
