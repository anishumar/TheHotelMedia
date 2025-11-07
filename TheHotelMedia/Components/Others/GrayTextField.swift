//
//  GrayTextField.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct GrayTextField: View {
    
    @Binding var textfieldText: String
    var title: String = "Password"
    var placeholder: String = "Password"
    var leftIcon: String = "LockIcon"
    var allowSpaces: Bool = true
    var isBold: Bool = false
    var isURL: Bool = false
    var keyboardtype: UIKeyboardType = .default
    var autocorrectionDisabled: Bool = true
    var textInputCapitalization: TextInputAutocapitalization = .words
    var hasCharcterLimit: Bool = false
    var characterLimit: Int = 10
    var defaultBorderColor: Color? = nil
    @Binding var rightIcon: String?
    var onRightButtonPressed: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
            }
            customTextfieldView
        }
        .foregroundStyle(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
        .font(.custom(Constants.comicFont, size: 14))
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
        
        GrayTextField(textfieldText: .constant(""), rightIcon: .constant("EyeSlash"))
    }
}

// MARK: - Components
extension GrayTextField {
    
    var customTextfieldView: some View {
        HStack(spacing: 10) {
            if !leftIcon.isEmpty {
                if isURL {
                    WebImage(url: URL(string: leftIcon))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 24))
                        .scaledToFit()
                        .foregroundColor(isBold ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white08_darkGray08)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 16)
                } else {
                    Image(leftIcon)
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 24))
                        .scaledToFit()
                        .foregroundColor(isBold ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white08_darkGray08)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 16)
                }
            }
            
            textfield
                .padding(.leading, leftIcon.isEmpty ? 16 : 0)
                .padding(.trailing, rightIcon == nil ? 8 : 0)
            
            if let rightIcon {
                Image(rightIcon)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 24))
                    .scaledToFit()
                    .foregroundColor(isBold ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white08_darkGray08)
                    .frame(width: 24, height: 24)
                    .padding(.leading, 20)
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
            
            if let defaultBorderColor {
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(defaultBorderColor)
            } else {
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(textfieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
            }
           
        }
    }
    
    
    private var textfield: some View {
        TextField(
            "\(placeholder)",
            text: $textfieldText,
            prompt:
                Text(placeholder)
                .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 14))
        )
        .keyboardType(keyboardtype)
        .autocorrectionDisabled(autocorrectionDisabled)
        .textInputAutocapitalization(textInputCapitalization)
        .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity)
        .onChange(of: textfieldText) { newValue in
            // Enforce character limit while typing
            if hasCharcterLimit {
                if newValue.count > characterLimit {
                    textfieldText = String(newValue.prefix(characterLimit))
                }
            }
            
            if !allowSpaces {
                textfieldText = newValue.replacingOccurrences(of: " ", with: "")
            }
        }
//        .onPasteCommand(of: [.plainText]) { items in
//            // Handle paste event and enforce character limit
//            if let pastedText = items.first?.string {
//                let newText = textfieldText + pastedText
//                if newText.count > characterLimit {
//                    // Limit the pasted content to fit within the character limit
//                    textfieldText = String(newText.prefix(characterLimit))
//                } else {
//                    textfieldText = newText
//                }
//            }
//        }
        
        
    }
}
