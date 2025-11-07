//
//  ContactTextField.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import SwiftUI
import CountryPickerView

struct ContactTextField: View {
    
    @Binding var contactText: String
    @Binding var selectedCountry: Country?
    var isBold: Bool = false
    var title: String = ""
    var placeholder: String = ""
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.isEmpty ? "contact_number".localized(localizationManager.language) : title)
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                
            HStack(spacing: 5) {
                if let image = selectedCountry?.flag {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            SUCountryPickerView(selectedCountry: $selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                } else {
                    Image("IndiaFlag")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .overlay(
                            SUCountryPickerView(selectedCountry: $selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                    
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                
                TextField(
                    "",
                    text: $contactText,
                    prompt:
                        Text( placeholder.isEmpty ? "contact_number".localized(localizationManager.language) : placeholder)
                        .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                        .font(.custom(Constants.comicFont, size: 14))
                )
                .withComicFont(14, color: isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
//                .focused($focusField, equals: .contact)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity)
                .onChange(of: contactText) { newValue in
                    // Enforce character limit while typing
                    if newValue.count > 10 {
                        contactText = String(newValue.prefix(10))
                    }
                }
                
            }
            .padding(.leading, 8)
            .padding(.trailing, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                CapsuleBackground(height: 46, borderColor: contactText.isEmpty ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
            )
            
        }
    }
}
