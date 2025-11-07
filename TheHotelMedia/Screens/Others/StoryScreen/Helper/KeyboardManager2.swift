//
//  KeyboardManager2.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import UIKit

class KeyboardManager2: ObservableObject {
    
    @Published private(set) var currentHeight: CGFloat = 0
    @Published private(set) var isKeyboardOpen = false

    private var notificationCenter: NotificationCenter
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(
            self,
            selector: #selector(keyBoardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyBoardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func keyBoardWillShow(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                currentHeight = keyboardSize.height - UIApplication.bottomSafeAreaHeightTHM
                isKeyboardOpen = true
            }
        }
        
    }
    
    @objc func keyBoardWillHide(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            isKeyboardOpen = false
            currentHeight = 0
        }
    }
}

extension UIApplication {
    
    static var topSafeAreaHeightTHM: CGFloat {
        return self.shared.windows.first?.safeAreaInsets.top ?? 0
    }
    
    static var bottomSafeAreaHeightTHM: CGFloat {
       return self.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
}

