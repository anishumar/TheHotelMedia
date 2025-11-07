//
//  EditBioView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI


struct EditBioView: View {
    
    @StateObject var viewModel: EditBioViewModel
    var onChangedBio: ((String) -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("edit_bio_heading".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            
            bioField
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Preview

struct EditBioView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditBioView(viewModel: EditBioViewModel(router: router, currentBio: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EditBioView {
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
            
            Text("bio".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.dismissScreen()
                onChangedBio?(viewModel.bioFieldText)
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
                    .opacity(viewModel.bioFieldText == viewModel.currentBio || viewModel.bioFieldText.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.bioFieldText.isEmpty || viewModel.bioFieldText == viewModel.currentBio)
        }
        .padding(.top, 16)
    }
    
    
    private var bioField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("bio".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
                if viewModel.bioFieldText.isEmpty {
                    Text("bio".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                        .offset(x: 10, y: 10)
                }
                
                TextEditor(text: $viewModel.bioFieldText)
                    .scrollContentBackground(.hidden)
                    .background(themeManager.currentTheme.darkGray05_white)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 120)
                    .padding(4)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: .init(lineWidth: 1))
                            .foregroundStyle(viewModel.bioFieldText.isEmpty ? themeManager.currentTheme.mediumGray_mediumGray03 : Color.hmIndigo)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
