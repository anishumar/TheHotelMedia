//
//  GuestDetailCard.swift
//  TheHotelMedia
//
//  Created by MAC on 19/02/25.
//

import SwiftUI
import CountryPickerView

struct GuestDetailCard: View {
    
    @Binding var personModel: PersonDetailModel
    var showOption: Bool = false
    @State var currentPerson: String = "other"
    @State var selectedCountry: Country? = nil
    var onPressedCross: (() -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            if showOption {
                HStack(spacing: 12) {
                    circleOptionView(type: "self", title: "My Self")
                    circleOptionView(type: "other", title: "Someone Else")
                    Spacer()
                }
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 10)
            }
            
            HStack {
                DropDownMenuView(viewModel: DropDownMenuViewModel(model: DropDownModel(id: "Title", answer: ["Mr", "Mrs", "Ms"], question: "Title", selectedAnswer: "Mr")), fontSize: 14, selectedFontSize: 14, titleFontSize: 14, optionFontSize: 14, isBold: true) { title in
                    personModel.title = title
                }
                .frame(maxWidth: Constants.screenWidth * 0.28)
                
                GrayTextField(textfieldText: $personModel.name, title: "Full Name", placeholder: "Full Name", leftIcon: "PersonIcon2", isBold: true, rightIcon: .constant(nil))
            }
            .zIndex(1.0)
            
            HStack {
                ContactTextField(contactText: $personModel.phoneNumber, selectedCountry: $selectedCountry, isBold: true)
                GrayTextField(textfieldText: $personModel.email, title: "Email", placeholder: "Email", leftIcon: "MessageIcon2", isBold: true, keyboardtype: .emailAddress, textInputCapitalization: .never, rightIcon: .constant(nil))
            }
            
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_darkGray008)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
        )
        .overlay(alignment: .topTrailing, content: {
            if !showOption {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    )
                    .onTapGesture {
                        onPressedCross?()
                    }
                    .padding(6)
            }
        })
        .onAppear {
            if showOption {
                currentPerson = "self"
            }
        }
        .onChange(of: currentPerson, perform: { newValue in
            if newValue == "self" {
                personModel.isSelf = true
            } else {
                personModel.isSelf = false
            }
        })
        .onChange(of: selectedCountry) { newValue in
            if let newValue {
                personModel.dialCode = newValue.phoneCode
            }
        }
    }
}


// MARK: - Components
extension GuestDetailCard {
    func circleOptionView(type: String, title: String) -> some View {
        HStack {
            if currentPerson == type {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 12, height: 12)
                    .padding(3)
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 0.5)
                            .fill(.hmDarkerGray)
                    }
            } else {
                Circle()
                    .fill(.hmDarkestGray.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 0.5)
                            .fill(.hmDarkerGray)
                    }
            }
            
            Text(title)
                .withComicFont(12, color: currentPerson == type ? themeManager.currentTheme.white_hmIndigo : themeManager.currentTheme.white04_darkGray04)
        }
        .onTapGesture {
            currentPerson = type
        }
    }
}
