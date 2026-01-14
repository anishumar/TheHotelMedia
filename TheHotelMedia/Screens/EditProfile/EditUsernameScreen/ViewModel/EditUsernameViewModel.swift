//
//  EditUsernameViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI
import SwiftfulRouting


class EditUsernameViewModel: ObservableObject {
    
    var router: AnyRouter
    var currentUsername: String
    @Published var usernameFieldText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
    init(router: AnyRouter, currentUsername: String) {
        self.router = router
        self.currentUsername = currentUsername
        usernameFieldText = currentUsername
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    /// Validates username format
    /// Username should be alphanumeric and may contain underscores/hyphens
    func isValidUsername(_ username: String) -> Bool {
        // Username validation: alphanumeric, underscore, hyphen, 3-30 characters
        let usernameRegex = "^[a-zA-Z0-9_-]{3,30}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
}
