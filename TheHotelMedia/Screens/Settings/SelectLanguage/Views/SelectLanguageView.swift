//
//  SelectLanguageView.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI

struct SelectLanguageView: View {
    
    @StateObject var viewModel: SelectLanguageViewModel
    @State var selectedLanguage: SelectedLanguage = .english
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            option(language: .english, title: "English")
            option(language: .hindi, title: "हिंदी")
            option(language: .marathi, title: "मराठी")
            option(language: .gujarati, title: "ગુજરાતી")
            option(language: .kannada, title: "ಕನ್ನಡ")
            option(language: .telugu, title: "తెలుగు")
            Spacer()
            
            if viewModel.initialScreen {
                CircleProgressButton(progress: .constant(100))
                    .padding()
                    .onTapGesture {
                        viewModel.showNextScreen()
                    }
            }
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .padding(.horizontal, 12)
        .padding(.top, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(
            CustomHeaderView(title: "language".localized(localizationManager.language), showBackButton: !viewModel.initialScreen) {
                viewModel.dismissScreen()
            }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            , alignment: .top
        )
        .onAppear {
            selectedLanguage = localizationManager.language
        }
        .onChange(of: selectedLanguage, perform: { value in
            localizationManager.language = selectedLanguage
        })
        
    }
}

// MARK: - Preview

struct SelectLanguageView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SelectLanguageView(viewModel: SelectLanguageViewModel(router: router))
    }
}


// MARK: - Components

extension SelectLanguageView {
    private func option(language: SelectedLanguage, title: String) -> some View {
        VStack {
            HStack {
                if selectedLanguage == language {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .frame(width: 24, height: 24)
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    }
                    .padding(.leading, 26)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1.4)
                        .fill(.hmDarkerGray)
                        .frame(width: 22, height: 22)
                        .padding(.leading, 26)
                }
                
                    
                
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
                
            )
            .onTapGesture {
                if !viewModel.initialScreen {
                    viewModel.changeLanguage(to: language) {
                        selectedLanguage = language
                    }
                } else {
                    selectedLanguage = language
                }
            }
            
        }
    }
}
