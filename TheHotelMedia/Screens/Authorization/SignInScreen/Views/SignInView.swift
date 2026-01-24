//
//  SignInView.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import ActivityIndicatorView
import AuthenticationServices
import SDWebImageSwiftUI
import KeychainAccess
//import FBSDKCoreKit
//import FBSDKLoginKit

enum SignInField {
    case email
    case password
}

struct SignInView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: SignInViewModel
    @StateObject var locationManager = LocationManager()
    @FocusState var focusField: SignInField?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
//    @State var fbLoginManager = LoginManager()
    
    // MARK: - Body
    var body: some View {
        let height = UIScreen.main.bounds.height

        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                VStack {
                    Image("Logo")
                        .resizable()
                        .frame(width: 92, height: 92)
                }
                .frame(height: height < 670 ? 120 : height * 0.25, alignment: .bottom)
//                .background(Color.red)
                VStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("strings_signin_title".localized(localizationManager.language))
                            .font(.custom(Constants.comicFont, size: 26))
                            .foregroundStyle(themeManager.currentTheme.label)
                        fieldSection
                        rememberMeSection
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: height < 670 ? (height - 120)/2 : height * 0.375)
//                .background(Color.green)
                VStack {
                    VStack(spacing: UIScreen.main.bounds.height < 670 ? 18 : 25){
                        CircleProgressButton(progress: .constant(100))
                            .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                            .onTapGesture {
                                if !viewModel.nextButtonDisabled {
                                    viewModel.login()
                                    
                                } else {
                                    viewModel.setErrorMessage()
                                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorText)
                                }
                            }
                        signupButtonSection
                        dividerSection
                        socialButtonSection
                            .padding(.bottom, 32)
                            
                    }
                    .padding(.top, 20)
                }
                .frame(height: height < 670 ? (height - 120)/2 : height * 0.375, alignment: .top)
//                .background(Color.yellow)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture {
                focusField = nil
            }
            .overlay(alignment: .topTrailing) {
                SocialLoginButton(icon: themeManager.currentTheme.CustomerSupport)
                    .scaleEffect(0.8)
                    .padding(.trailing, 12)
                    .padding(.top, UIApplication.topSafeAreaHeightTHM)
                    .onTapGesture {
                        viewModel.showSupportScreen()
                    }
                    
            }
            
        }
        .scrollDisabled(true)
        .ignoresSafeArea()
        .background(
            BackgroundImageView()
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay {
            ZStack {
                if viewModel.showNotApprovedModal {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        WebImage(url: Bundle.main.url(forResource: "process", withExtension: "gif"))
                            .resizable()
                            .scaledToFit()
//                            .frame(width: 100, height: 100)
                            .frame(width: 150, height: 150)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                    viewModel.showNotApprovedModal = false
                                }
                            }
                            
                        Text(viewModel.errorText)
                            .withComicFont(12, color: themeManager.currentTheme.label)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        }
        .overlay(content: {
            if viewModel.showProfessionModal {
                VStack(spacing: 16) {
                    HStack {
                        Text("Add Profession")
                            .withComicFont(16, color: themeManager.currentTheme.label)
                        Spacer()
                        Image(systemName: "xmark")
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                                    .frame(width: 22, height: 22)
                            )
                            .onTapGesture {
                                viewModel.showProfessionModal = false
                            }
                        
                        
                    }
                    VStack {
                        ZStack {
                            roundedBackground
                                .frame(height: 46)
                                .onTapGesture {
                                    withAnimation {
                                        if !viewModel.professions.isEmpty {
                                            haptics(.light)
                                            viewModel.dropDownOpen.toggle()
                                        }
                                    }
                                }
                            dropDownField
                        }
                        .overlay(alignment: .top) {
                            dropDownMenu
                                .offset(y: 50)
                        }
                        
                        if viewModel.dropDownOpen {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: CGFloat(viewModel.professions.count) * 44 + 50)
                        }
                        
                        if let name = viewModel.selectedProfession?.name, name.localized(localizationManager.language) == "Others".localized(localizationManager.language) {
                            GrayTextField(textfieldText: $viewModel.otherProfessionFieldText, title: "", placeholder: "profession".localized(localizationManager.language) , leftIcon: "", rightIcon: .constant(nil))
                        }
                    }
                    
                    Button {
                        guard let selectedProfession = viewModel.selectedProfession else {
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Please select a profession.".localized(localizationManager.language))
                            return
                        }
                        
                        if selectedProfession.name == "Others".localized(localizationManager.language) {
                            guard viewModel.otherProfessionFieldText.isNotEmpty else {
                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Please enter a profession name.".localized(localizationManager.language))
                                return
                            }
                            viewModel.updateProfession(profession: viewModel.otherProfessionFieldText)
                            
                        } else {
                            viewModel.updateProfession(profession: selectedProfession.name ?? "")
                        }
                        
                    } label: {
                        Text("Submit".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray06_darkGray008)
                )
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)

            }
        })
        .onChange(of: locationManager.currentLocation, perform: { newValue in
            if let newValue {
                viewModel.latitude = newValue.latitude.magnitude
                viewModel.longitude = newValue.longitude.magnitude
            }
        })
        .onAppear {
            locationManager.requestLocation()
//            Constants.printNamesOfFont()
        }
    }
}

// MARK: - Preview

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SignInView(viewModel: SignInViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
            
    }
}

// MARK: - Functions

extension SignInView {
    func nextField() {
        switch focusField {
        case .email:
            focusField = .password
        case .password:
            focusField = .email
        case .none:
            focusField = .password
        }
    }
}

// MARK: - Components
extension SignInView {
    
    private var keyboardButtons: some View {
        HStack {
            
            Button(action: {
                nextField()
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
    
    
    private var switchButton: some View {
        Capsule()
            .fill(viewModel.rememberMe ? .white : .hmDarkestGray)
            .frame(width: 34, height: 22)
            .onTapGesture {
                viewModel.rememberMe.toggle()
            }
            .overlay(
                Circle()
                    .fill(viewModel.rememberMe ? .hmIndigo : .white)
                    .frame(width: 18)
                    .padding(.horizontal, 2)
                    
                ,alignment: viewModel.rememberMe ? .trailing : .leading
            )
            .animation(.linear(duration: 0.2), value: viewModel.rememberMe)
    }
    
    
    private var fieldSection: some View {
        Group{
            GrayTextField(
                textfieldText: $viewModel.emailFieldText,
                title: "email".localized(localizationManager.language),
                placeholder: "strings_signin_email_placeholder".localized(localizationManager.language),
                leftIcon: "MessageIcon2",
                allowSpaces: false,
                keyboardtype: .emailAddress,
                textInputCapitalization: .never,
                rightIcon: .constant(nil),
                onRightButtonPressed: nil
            )
            .focused($focusField, equals: .email)

            
            PasswordTextField(
                textfieldText: $viewModel.passwordFieldText,
                title: "password".localized(localizationManager.language),
                placeholder: "strings_signin_password_placeholder".localized(localizationManager.language),
                leftIcon: "LockIcon2",
                rightIcon: $viewModel.passwordRightIcon,
                isSecure: $viewModel.isSecure
            ) {
                viewModel.isSecure.toggle()
                viewModel.passwordRightIcon = viewModel.isSecure ? "EyeSlash" : "Eye"
            }
            .focused($focusField, equals: .password)
        }
    }
    
    
    private var rememberMeSection: some View {
        HStack {
            Spacer()
            
            Button(action: {
                viewModel.showForgotPasswordScreen()
            }, label: {
                Text("forgot_password".localized(localizationManager.language))
                    .foregroundStyle(.hmIndigo)
                    .font(.custom(Constants.comicFont, size: 14))
            })
        }
    }
    
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.mediumGray_mediumGray03)
            .frame(height: 1.5)
//            .frame(maxWidth: .infinity)
    }
    
    
    private var dividerSection: some View {
        HStack {
            divider
            Text("Log in with social")
                .font(.system(size: 14))
                .foregroundStyle(themeManager.currentTheme.label)
                .layoutPriority(1)
//            Text("OR")
//                .foregroundStyle(themeManager.currentTheme.label)
            divider
        }
        .padding(.horizontal, 16)
    }
    
    
    private var socialButtonSection: some View {
        HStack(spacing: 32) {
//            Button(action: {
//                viewModel.signUpWithFacebook()
//                
//            }, label: {
//                SocialLoginButton(icon: "FacebookIcon")
//                    .frame(width: 48, height: 48)
//            })
            Button(action: {
                viewModel.signUpWithGoogle()
            }, label: {
                SocialLoginButton(icon: "GoogleIcon")
                    .frame(width: 48, height: 48)
            })
            
            Button(action: {
                viewModel.showPhoneLoginScreen()
            }, label: {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.darkGray_hmIndigo03)
                        .frame(width: 48)
                    
                    Circle()
                        .stroke(lineWidth: 1)
                        .fill(Color.hmIndigo)
                        .frame(width: 48)
                    
                    Image(systemName: "phone.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(themeManager.currentTheme.label)
                }
                .frame(width: 48, height: 48)
            })
            
            ZStack {
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    
                    switch result {
                    case .success(let auth):
                        
                        switch auth.credential {
                        case let credential as ASAuthorizationAppleIDCredential:
                            
                            let firstName = credential.fullName?.givenName
                            let middleName = credential.fullName?.middleName
                            let lastName = credential.fullName?.familyName
                            let identifier = credential.user
                            
                            if let email = credential.email {
                                KeychainManager.shared.saveEmailToKeychain(key: identifier, email: email)
                            }
                            
                            var fullName: String = ""
                            
                            if let firstName, !firstName.isEmpty {
                                fullName.append(firstName)
                                
                                if let middleName, !middleName.isEmpty {
                                    fullName.append(" \(middleName)")
                                }
                                
                                if let lastName, !lastName.isEmpty {
                                    fullName.append(" \(lastName)")
                                }
                            }
                            
                            if let identityTokenData = credential.identityToken,
                               let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                                
                                let email = KeychainManager.shared.retrieveEmailFromKeychain(key: identifier)
                                
                                if !fullName.isEmpty {
                                    viewModel.appleSocialLogin(idToken: identityTokenString, name: fullName, email: email)
                                } else {
                                    viewModel.appleSocialLogin(idToken: identityTokenString, email: email)
                                }
                            } else {
                                print("Apple ID Token is not available.")
                            }
                            
                        default:
                            break
                        }
                        
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                }
                .frame(width: 45, height: 45)
                .overlay(content: {
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .allowsHitTesting(false)
                })
                .clipped()
                
                Button(action: {
                    print("Wrong button pressed.")
                }, label: {
                    SocialLoginButton(icon: "AppleIcon")
                        .frame(width: 48, height: 48)
                })
                .allowsHitTesting(false)
            }
            
        }
    }
    
    
    private var signupButtonSection: some View {
        HStack(spacing: 3) {
            Text("strings_signin_don't_have_account".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
            
            Button(action: {
                
            }, label: {
                Text("signup".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 13))
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                    .background(Color.black.opacity(0.001))
                    .onTapGesture {
                        viewModel.showSignUpAccountTypeView()
                    }
            })
        }
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            Capsule()
                .fill(themeManager.currentTheme.darkGray06_white)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(viewModel.selectedProfession != nil ? .hmIndigo : .hmDarkerGray)
        }
    }
    
    
    private func professionOption(profession: Profession) -> some View {
        HStack {
            Text((profession.name ?? "").localized(localizationManager.language))
                .foregroundStyle(viewModel.selectedProfession == profession ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 16))
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
                withAnimation {
                    viewModel.dropDownOpen.toggle()
                }
            }
            viewModel.selectedProfession = profession
        }
    }
    
    
    private var menuBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(themeManager.currentTheme.darkGray05_white)
            
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .fill(.hmDarkerGray)
        }
    }
    
    
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
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
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
}

extension SignInView {
    func saveEmail(key: String, email: String) {
        if UserDefaults.standard.string(forKey: key) == nil {
            UserDefaults.standard.set(email, forKey: key)
        }
    }
    
    
    func retrieveEmail(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
}


