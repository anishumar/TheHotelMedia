//
//  ChangePasswordScreenViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation
import SwiftfulRouting
import Combine


class ChangePasswordScreenViewModel: ObservableObject {
    
    var router: AnyRouter
    var email: String
    var resetToken: String
    let dataManager = ChangePasswordManager()
    var cancellables = Set<AnyCancellable>()
    @Published var showLoadingIndicator: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var errorText: String = ""
    @Published var passwordFieldText: String = ""
    @Published var isSecure: Bool = true
    @Published var rightIcon: String? = "EyeSlash"
    @Published var passwordFieldText2: String = ""
    @Published var isSecure2: Bool = true
    @Published var rightIcon2: String? = "EyeSlash"
    
    init(router: AnyRouter, email: String, resetToken: String) {
        self.router = router
        self.email = email
        self.resetToken = resetToken
    }
    
    
    func addSubscribers() {
        $passwordFieldText2
            .combineLatest($passwordFieldText)
            .debounce(for: 0.5 , scheduler: RunLoop.main)
            .sink { [weak self] (text2, text1) in
                guard let self else { return }
                
                if text1.count > 2 && text1 == text2 {
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
    
    func dismissAllScreens() {
        router.dismissScreenStack()
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

extension ChangePasswordScreenViewModel {
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
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2 ) { [weak self] in
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
