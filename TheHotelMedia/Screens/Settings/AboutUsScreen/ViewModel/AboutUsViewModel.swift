//
//  AboutUsViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class AboutUsViewModel: ObservableObject {
    
    var router: AnyRouter
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
