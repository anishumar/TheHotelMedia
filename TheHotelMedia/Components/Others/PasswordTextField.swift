//
//  PasswordTextField.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI

struct PasswordTextField: View {
    
    enum PasswordState {
        case hidePasswordField
        case showPasswordField
    }
    
    @Binding var textfieldText: String
    var title: String = "Password"
    var placeholder: String = "Password"
    var leftIcon: String = "LockIcon"
    var keyboardtype: UIKeyboardType = .asciiCapable
    var autocorrectionDisabled: Bool = true
    var text: String = ""
    var isDisabled: Bool = false
    @Binding var rightIcon: String?
    @Binding var isSecure: Bool
    @FocusState var secureFieldFocused: Bool
    @FocusState var textFieldFieldFocused: Bool
    var onRightButtonPressed: (() -> Void)?
    @State var visibilityChanged: Bool = false
    @State var oldText: String = ""
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
            customTextfieldView
        }
        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
        .font(.custom(Constants.comicFont, size: 14))
        .onChange(of: isSecure) { newValue in
            secureFieldFocused = newValue
            textFieldFieldFocused = !newValue
            oldText = textfieldText
            visibilityChanged = true
        }
    }
}

#Preview {
    ZStack {
        Rectangle()
            .overlay(
                Image("SignInBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    
            )
            .clipped()
            .ignoresSafeArea()
        
        PasswordTextField(textfieldText: .constant(""), rightIcon: .constant("EyeSlash"), isSecure: .constant(true))
    }
}

// MARK: - Components
extension PasswordTextField {
    
    var customTextfieldView: some View {
        HStack(spacing: 10) {
            Image(leftIcon)
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 24))
                .scaledToFit()
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .frame(width: 24, height: 24)
                .padding(.leading, 16)
            
            ZStack {
                textfield
                securefield
            }
//            SecureTextField(
//                text: $textfieldText,
//                isSecure: isSecure,
//                placeholder: placeholder,
//                font: UIFont(name: Constants.comicFont, size: 14) ?? UIFont.systemFont(ofSize: 14)
//            )
            
            
            if let rightIcon {
                Image(rightIcon)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 24))
                    .scaledToFit()
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.001))
                    .onTapGesture {
                        onRightButtonPressed?()
                    }
            }
            
        }
        .frame(height: 46)
        .background(
            roundedBackground
        )
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            Capsule()
                .fill(themeManager.currentTheme.darkGray05_white)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(textfieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
        }
    }
    
    
    private var textfield: some View {
        TextField(
            "",
            text: $textfieldText,
            prompt:
                Text(placeholder)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 14))
        )
        .focused($textFieldFieldFocused)
        .disabled(isDisabled)
        .keyboardType(keyboardtype)
        .textContentType(.password)
        .autocorrectionDisabled(autocorrectionDisabled)
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity)
        .opacity(isSecure ? 0 : 1)
        
    }
    
    
    private var securefield: some View {
        SecureField(
            "",
            text: $textfieldText,
            prompt:
                Text(placeholder)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 14))
        )
        .focused($secureFieldFocused)
        .disabled(isDisabled)
        .textInputAutocapitalization(.never)
        .keyboardType(keyboardtype)
        .autocorrectionDisabled(autocorrectionDisabled)
        .textContentType(.password)
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity)
        .opacity(isSecure ? 1 : 0)
        .onChange(of: textfieldText) { newValue in
            if visibilityChanged {
                if newValue.count == 1 {
                    textfieldText = String(oldText) + String(newValue)
                    visibilityChanged = false
                }
            }
            oldText = ""
        }
        
    }
}

