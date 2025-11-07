//
//  SettingTermsCondtionViewModel.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI
import SwiftfulRouting


class SettingTermsConditionViewModel : ObservableObject {
    
    var router: AnyRouter
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
