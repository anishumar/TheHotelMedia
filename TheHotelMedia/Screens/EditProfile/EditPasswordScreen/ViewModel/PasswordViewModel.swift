//
//  PasswordViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class PasswordViewModel: ObservableObject {
    
    var router: AnyRouter
    @Published var passwordFieldText: String = "some_password"
    @Published var isSecure: Bool = true
    @Published var rightIcon: String? = "EyeSlash"
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showEnterEmailScreen() {
        router.showScreen(.push) { router in
            EnterEmailView(viewModel: EnterEmailViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}
