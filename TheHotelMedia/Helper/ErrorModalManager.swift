//
//  ErrorModalManager.swift
//  TheHotelMedia
//
//  Created by MAC on 27/09/24.
//

import SwiftUI
import SwiftfulRouting


class ErrorModalManager {
    // This function can be called by any view model
    static func showErrorModal(router: AnyRouter, errorText: String, completion: @escaping () -> Void = {}) {
        router.showModal(transition: .move(edge: .top)) {
            BottomAlert(message: errorText)
        }
        print(errorText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            router.dismissModal()
            completion()
        }
    }
}
