//
//  IndividualSignupView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import ActivityIndicatorView

enum IndividualSignupField {
    case name
    case email
    case password
    case contact
}

struct IndividualSignupView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: IndividualSignupViewModel
    @FocusState var focusField: IndividualSignupField?
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: UIScreen.main.bounds.height < 670 ? 30 : 55) {
                    logo
                    VStack(alignment: .leading, spacing: 20) {
                        title
                        textFieldSection
                        VStack(alignment: .leading) {
                            Text("profession".localized(localizationManager.language).capitalized)
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .font(.custom(Constants.comicFont, size: 14))
                            
                            ZStack {
                                roundedBackground
                                    .frame(height: 46)
                                    .onTapGesture {
                                        if !viewModel.professions.isEmpty {
                                            haptics(.light)
                                            viewModel.dropDownOpen.toggle()
                                        }
                                    }
                                dropDownField
                            }
                            .overlay(alignment: .top) {
                                dropDownMenu
                                    .offset(y: 50)
                            }
                            
                            if viewModel.dropDownOpen {
                                Spacer(minLength: CGFloat(viewModel.professions.count) * 44 + 50)
                            }
                            
                            if let name = viewModel.selectedProfession?.name, name.localized(localizationManager.language) == "Others".localized(localizationManager.language) {
                                GrayTextField(textfieldText: $viewModel.otherProfessionFieldText, title: "", placeholder: "profession".localized(localizationManager.language) , leftIcon: "", rightIcon: .constant(nil))
                            }
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    bottomButtonSection
                }
            }
            .clipped()
        }
        .preferredColorScheme(.dark)
        .onChange(of: locationManager.currentLocation, perform: { newValue in
            if let newValue {
                viewModel.latitude = newValue.latitude.magnitude
                viewModel.longitude = newValue.longitude.magnitude
            }
        })
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getPrefessions()
            locationManager.requestLocation()
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

struct IndividualSignupView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        IndividualSignupView(viewModel: IndividualSignupViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}

// MARK: - Functions

extension IndividualSignupView {
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
extension IndividualSignupView {
    
    private var dropDownField: some View {
        HStack {
            Text((viewModel.selectedProfession?.name ?? "profession").localized(localizationManager.language))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 14))
            
            Spacer()
                .background(.black.opacity(0.001))
                
            
            Image(systemName: "chevron.down")
                .fontWeight(.semibold)
                .rotationEffect(Angle(degrees: viewModel.dropDownOpen ? 180 : 0))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
    }
    
    
    private var dropDownMenu: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.professions, id: \.self) { profession in
                professionOption(profession: profession)
            }
        }
        .background(menuBackground)
        .scaleEffect(y: viewModel.dropDownOpen ? 1 : 0, anchor: .top)
        .animation(.smooth(duration: 0.3), value: viewModel.dropDownOpen)
    }
    
    private var roundedBackground: some View {
        ZStack {
            Capsule()
                .fill(themeManager.currentTheme.darkGray_white)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(viewModel.selectedProfession != nil ? .hmIndigo : .hmDarkerGray)
        }
    }
    
    
    private func professionOption(profession: Profession) -> some View {
        HStack {
            Text((profession.name ?? "").localized(localizationManager.language))
                .foregroundStyle(viewModel.selectedProfession == profession ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 18))
                .padding(.horizontal, 16)
            Spacer()
            
        }
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(viewModel.selectedProfession?.name == profession.name ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
        )
        .onTapGesture {
            haptics(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.dropDownOpen.toggle()
            }
            viewModel.selectedProfession = profession
        }
    }
    
    
    private var menuBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(themeManager.currentTheme.darkGray05_white)
            
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 2)
                .fill(.hmDarkerGray)
        }
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
    
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
                .padding(.top, UIScreen.main.bounds.height < 670 ? 20 : 100)
        }
    }
    
    
    private var title: some View {
        Group {
            Text("individual_sign_up".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
        }
    }
    
    
    private var textFieldSection: some View {
        Group {
            GrayTextField(
                textfieldText: $viewModel.nameFieldText,
                title: "name".localized(localizationManager.language),
                placeholder: "full_name".localized(localizationManager.language),
                leftIcon: "PersonIcon2",
                rightIcon: .constant(nil)
            )
            .focused($focusField, equals: .name)
            
            GrayTextField(
                textfieldText: $viewModel.emailFieldText,
                title: "email".localized(localizationManager.language),
                placeholder: "email".localized(localizationManager.language),
                leftIcon: "MessageIcon2",
                keyboardtype: .emailAddress,
                textInputCapitalization: .never,
                rightIcon: .constant(nil),
                onRightButtonPressed: nil
            )
            .focused($focusField, equals: .email)
            
            PasswordTextField(
                textfieldText: $viewModel.passwordFieldText,
                title: "password".localized(localizationManager.language),
                placeholder: "your_password".localized(localizationManager.language),
                leftIcon: "LockIcon2",
                rightIcon: $viewModel.passwordRightIcon,
                isSecure: $viewModel.isSecure
            ){
                viewModel.isSecure.toggle()
                viewModel.passwordRightIcon = viewModel.isSecure ? "EyeSlash" : "Eye"
            }
            .focused($focusField, equals: .password)
            
            contactField
            
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
                            Task {
                                await viewModel.createNewAccount()
                            }
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
                .focused($focusField, equals: .contact)
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
}
