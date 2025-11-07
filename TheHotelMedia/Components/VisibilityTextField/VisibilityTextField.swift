//
//  VisibilityTextField.swift
//  TheHotelMedia
//
//  Created by MAC on 09/01/25.
//

import UIKit
import SwiftUI


import UIKit

class VisibilityTextField: UITextField {
    
    var isSecure: Bool = true {
        didSet {
            updateSecureState()
        }
    }
    
    var customFont: UIFont? {
        didSet {
            font = customFont
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isSecureTextEntry = true // Default to secure mode
    }
    
    private func updateSecureState() {
        isSecureTextEntry = isSecure
        
        // Fix cursor position when toggling secure entry
        if let existingText = text, !existingText.isEmpty {
            let currentText = text
            deleteBackward()
            insertText(currentText ?? "")
        }
    }
}




struct VisibilityTextFieldWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var isSecure: Bool
    var placeholder: String
    var keyboardType: UIKeyboardType
    var isDisabled: Bool
    var font: UIFont?
    
    func makeUIView(context: Context) -> VisibilityTextField {
        let textField = VisibilityTextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.customFont = font
        textField.isSecure = isSecure
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: VisibilityTextField, context: Context) {
        uiView.text = text
        uiView.isSecure = isSecure // Ensure the secure state is updated
        uiView.isUserInteractionEnabled = !isDisabled
        uiView.customFont = font
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: VisibilityTextFieldWrapper
        
        init(_ parent: VisibilityTextFieldWrapper) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                parent.text = textField.text ?? ""
            }
        }
        
        // Handle the "Return" key tap
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                textField.resignFirstResponder() // Dismiss the keyboard
            }
            return true
        }
    }
}



