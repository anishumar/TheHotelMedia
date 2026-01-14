//
//  EditUsernameView.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI

struct EditUsernameView: View {
    
    @StateObject var viewModel: EditUsernameViewModel
    var onChangedUsername: ((String) -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("Edit your username")
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GrayTextField(
                    textfieldText: $viewModel.usernameFieldText,
                    title: "username".localized(localizationManager.language),
                    placeholder: "username".localized(localizationManager.language),
                    leftIcon: "PersonIcon2",
                    keyboardtype: .asciiCapable,
                    autocorrectionDisabled: true,
                    textInputCapitalization: .never,
                    rightIcon: .constant(nil)
                )
                
                // Username validation hint
                if !viewModel.usernameFieldText.isEmpty && !viewModel.isValidUsername(viewModel.usernameFieldText) {
                    Text("Username must be 3-30 characters, alphanumeric, underscore, or hyphen")
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -12)
                }
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview

struct EditUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditUsernameView(viewModel: EditUsernameViewModel(router: router, currentUsername: "testuser"))
            .environmentObject(LocalizationManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}


// MARK: - Components

extension EditUsernameView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("username".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                guard viewModel.isValidUsername(viewModel.usernameFieldText) else {
                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Please enter a valid username (3-30 characters, alphanumeric, underscore, or hyphen)")
                    return
                }
                
                viewModel.dismissScreen()
                onChangedUsername?(viewModel.usernameFieldText)
            }, label: {
                Circle()
                    .fill(.hmIndigo.opacity(0.5))
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
                    .opacity(canSave ? 1.0 : 0.5)
            })
            .disabled(!canSave)
        }
        .padding(.top, 16)
    }
    
    private var canSave: Bool {
        !viewModel.usernameFieldText.isEmpty &&
        viewModel.usernameFieldText != viewModel.currentUsername &&
        viewModel.isValidUsername(viewModel.usernameFieldText)
    }
}
