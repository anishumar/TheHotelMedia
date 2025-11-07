//
//  KeyboardHeightHelper.swift
//  HotelMedia
//
//  Created by MAC on 14/08/24.
//

import SwiftUI

class KeyboardHeightHelper: ObservableObject {
    
    @Published var keyboardHeight: CGFloat = 0
    
    init() {
        self.listenForKeyboardNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self) // Clean up observers when deallocated
    }
    
    private func listenForKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification,
                                               object: nil,
                                               queue: .main) { [weak self] (notification) in
            guard let self = self, let userInfo = notification.userInfo,
                let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.keyboardHeight = keyboardRect.height
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
                                               object: nil,
                                               queue: .main) { [weak self] (notification) in
            DispatchQueue.main.async {
                self?.keyboardHeight = 0
            }
        }
    }
}
