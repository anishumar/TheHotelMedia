//
//  EditNameView.swift
//  HotelMedia
//
//  Created by MAC on 19/08/24.
//

import SwiftUI

struct EditNameView: View {
    
    @StateObject var viewModel: EditNameViewModel
    var onChangedName: ((String) -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("edit_name_heading".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GrayTextField(
                    textfieldText: $viewModel.nameFieldText,
                    title: "name".localized(localizationManager.language),
                    placeholder: "name".localized(localizationManager.language),
                    leftIcon: "PersonIcon2",
                    rightIcon: .constant(nil)
                )
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Preview

struct EditNameView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditNameView(viewModel: EditNameViewModel(router: router, currentName: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EditNameView {
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
            
            Text("name".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.dismissScreen()
                onChangedName?(viewModel.nameFieldText)
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
                    .opacity(viewModel.nameFieldText == viewModel.currentName || viewModel.nameFieldText.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.nameFieldText.isEmpty || viewModel.nameFieldText == viewModel.currentName)
        }
        .padding(.top, 16)
    }
}
