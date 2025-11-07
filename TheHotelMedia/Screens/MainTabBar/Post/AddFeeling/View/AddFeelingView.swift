//
//  AddFeelingView.swift
//  HotelMedia
//
//  Created by MAC on 04/09/24.
//

import SwiftUI

struct AddFeelingView: View {
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AddFeelingViewModel
    @Binding var selectedFeeling: Feeling?
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible())
    ]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                searchField
                
                if let feeling = viewModel.selectedFeeling {
                    selectedFeelingView(feeling: feeling)
                }
                
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.arrayOfFeelings) { feeling in
                        feelingView(feeling: feeling)
                            .onTapGesture {
                                viewModel.selectedFeeling = feeling
                                selectedFeeling = feeling
                                dismiss.callAsFunction()
                            }
                        
                    }
                }
            }
            .padding(.top, 55)
            .padding(.horizontal, 12)
        }
        .clipped()
        .background(
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
        )
        .overlay(
            header
                .padding(.bottom, 4)
                .padding(.horizontal, 12)
                .background(
                    themeManager.currentTheme.backgroundColor
                )
            , alignment: .top
        )
    }
}

// MARK: - Preview
struct AddFeelingView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        AddFeelingView(viewModel: AddFeelingViewModel(router: router), selectedFeeling: .constant(nil))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension AddFeelingView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    dismiss.callAsFunction()
                }
            
            Text("feeling_activity".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .padding(.top, 16)
    }
    
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .fontWeight(.semibold)
            
            TextField(
                "",
                text: $viewModel.searchFieldText,
                prompt: Text("search".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            )
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity)
            
        }
        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            CapsuleBackground(borderColor: .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private func feelingView(feeling: Feeling) -> some View {
        HStack(spacing: 4) {
            Text(feeling.emoji)
                .font(.system(size: 28))
                
            Text(feeling.title)
                .font(.custom(Constants.comicFont, size: 15))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.black09_white)
                    .padding(3)
            }
        )
    }
    
    
    private func selectedFeelingView(feeling: Feeling) -> some View {
        HStack(spacing: 15) {
            Text(feeling.emoji)
                .font(.system(size: 32))
            
            Text(feeling.title)
                .font(.custom(Constants.comicFont, size: 14))
                .lineLimit(1)
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            xmarkButton
                .onTapGesture {
                    viewModel.selectedFeeling = nil
                    selectedFeeling = nil
                }
        }
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
        )
    }
    
    
    private var xmarkButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 22)
            
            Image(systemName: "xmark")
                .renderingMode(.template)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
