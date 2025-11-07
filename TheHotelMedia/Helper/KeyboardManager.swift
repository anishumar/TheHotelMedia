//
//  KeyboardManager.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import SwiftUI
import UIKit

struct KeyboardManager: UIViewControllerRepresentable {
    @Binding var bottomPadding: CGFloat

    class Coordinator: NSObject {
        var parent: KeyboardManager
        
        init(parent: KeyboardManager) {
            self.parent = parent
        }
        
        @objc func keyboardWillChange(notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            
            let keyboardHeight = keyboardFrame.height
            self.parent.bottomPadding = keyboardHeight
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
