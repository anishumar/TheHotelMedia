//
//  CustomTextField.swift
//  TheHotelMedia
//
//  Created by MAC on 28/01/25.
//

import SwiftUI
import UIKit

struct SecureTextField: UIViewRepresentable {
    @Binding var text: String
    var isSecure: Bool
    var placeholder: String
    var font: UIFont
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SecureTextField
        
        init(_ parent: SecureTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.isSecureTextEntry = isSecure
        textField.font = font
        textField.textColor = .white.withAlphaComponent(0.6)
        textField.borderStyle = .none
        
        // Set placeholder with the same font and a custom color
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label // Change color if needed
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecure
        
        // Update placeholder dynamically if needed
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.6) // Change color if needed
        ]
        uiView.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
    }
}
