//
//  EditNameViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class EditNameViewModel: ObservableObject {
    
    var router: AnyRouter
    var currentName: String
    @Published var nameFieldText: String = ""
    
    init(router: AnyRouter, currentName: String) {
        self.router = router
        self.currentName = currentName
        nameFieldText = currentName
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
