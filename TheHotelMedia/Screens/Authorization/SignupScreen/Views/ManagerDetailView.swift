//
//  ManagerDetailView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import ActivityIndicatorView

enum ManagerSignupField {
    case name
    case email
    case password
    case contact
}

struct ManagerDetailView: View {
    // MARK: - Properties
    @StateObject var viewModel: ManagerDetailViewModel
    @FocusState var focusField: ManagerSignupField?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 37) {
                    Image("Logo")
                        .resizable()
                        .frame(width: 92, height: 92)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 26) {
                        title
                        
                        GrayTextField(textfieldText: $viewModel.nameFieldText,title: "name".localized(localizationManager.language), placeholder: "name".localized(localizationManager.language), leftIcon: "PersonIcon2", rightIcon: .constant(nil))
                            .focused($focusField, equals: .name)
                        
                        GrayTextField(
                            textfieldText: $viewModel.emailFieldText,
                            title: "email".localized(localizationManager.language),
                            placeholder: "email".localized(localizationManager.language),
                            leftIcon: "MessageIcon2",
                            keyboardtype: .emailAddress,
                            textInputCapitalization: .never,
                            rightIcon: .constant(nil)
                        )
                            .focused($focusField, equals: .email)
                        
                        PasswordTextField(
                            textfieldText: $viewModel.passwordFieldText,
                            title: "password".localized(localizationManager.language),
                            placeholder: "enter_your_password".localized(localizationManager.language),
                            leftIcon: "LockIcon2",
                            rightIcon: $viewModel.passwordRightIcon,
                            isSecure: $viewModel.isSecure
                        ) {
                            viewModel.isSecure.toggle()
                            viewModel.passwordRightIcon = viewModel.isSecure ? "EyeSlash" : "Eye"
                        }
                        .focused($focusField, equals: .password)
                        
                        contactField
                        
                        bottomButtonSection
                            .padding(.top, 50)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                }
            }
            .clipped()
        }
//        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.addSubscribers()
        }
        .onDisappear {
            viewModel.cancelSubcriptions()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview

struct ManagerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ManagerDetailView(viewModel: ManagerDetailViewModel(router: router, businessData: BusinessData(email: "", name: "", accountType: "", dialCode: "", phoneNumber: "", password: "", businessName: "", businessEmail: "", businessPhoneNumber: "", businessDialCode: "", businessType: "", businessSubType: "", businessDescription: "", businessWebsite: "", gstn: "", street: "", city: "", state: "", zipCode: "", country: "", lng: "", lat: "", placeID: "")))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions

extension ManagerDetailView {
    func nextField() {
        switch focusField {
        case .name:
            focusField = .email
        case .email:
            focusField = .password
        case .password:
            focusField = .contact
        case .contact:
            focusField = .name
        case .none:
            focusField = .name
        }
    }
        
     
    func previousField() {
        switch focusField {
        case .name:
            focusField = .contact
        case .email:
            focusField = .name
        case .password:
            focusField = .email
        case .contact:
            focusField = .password
        case .none:
            focusField = .contact
        }
    }
        
}


// MARK: - Components
extension ManagerDetailView {
    
    private var contactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("contact_number".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                
            HStack(spacing: 5) {
                if let image = viewModel.selectedCountry?.flag {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                } else {
                    Image("IndiaFlag")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                    
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                
                TextField(
                    "",
                    text: $viewModel.contactFieldText,
                    prompt:
                        Text("contact_number".localized(localizationManager.language))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .font(.custom(Constants.comicFont, size: 14))
                )
                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                .focused($focusField, equals: .email)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.contactFieldText) { newValue in
                    // Enforce character limit while typing
                    if newValue.count > 10 {
                        viewModel.contactFieldText = String(newValue.prefix(10))
                    }
                }
                
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                CapsuleBackground(height: 46, borderColor: viewModel.contactFieldText.isEmpty ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
            )
            
        }
    }
    
    
    private var title: some View {
        Group {
            Text("manager_information".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
        }
    }
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                            .frame(width: 48)
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .tint(.white)
                    }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            VStack {
                CircleProgressButton(progress: .constant(100))
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.businessSignup()
                            
                        } else {
                            viewModel.setErrorMessage()
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorMessage)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
    
    private var keyboardButtons: some View {
        HStack {
            
            Button(action: {
                previousField()
            }, label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Button(action: {
                nextField()
            }, label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                    
            })
        }
    }
}
