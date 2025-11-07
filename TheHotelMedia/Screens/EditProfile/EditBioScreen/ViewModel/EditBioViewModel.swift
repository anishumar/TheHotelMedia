//
//  EditBioViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class EditBioViewModel: ObservableObject {
    
    var router: AnyRouter
    let currentBio: String
    @Published var bioFieldText: String = ""
    
    init(router: AnyRouter, currentBio: String) {
        self.router = router
        self.currentBio = currentBio
        bioFieldText = currentBio
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
