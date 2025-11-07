//
//  EditEmailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class EditEmailViewModel: ObservableObject {
    
    var router: AnyRouter
    let currentEmail: String
    @Published var emailFieldText: String = ""
    
    init(router: AnyRouter, currentEmail: String) {
        self.router = router
        self.currentEmail = currentEmail
        emailFieldText = currentEmail
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
