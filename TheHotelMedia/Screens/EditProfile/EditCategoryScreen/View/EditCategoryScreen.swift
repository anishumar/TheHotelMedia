//
//  EditCategoryScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 30/09/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct EditCategoryScreen: View {
    
    @StateObject var viewModel: EditCategoryViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            Text("edit_category_headline".localized(localizationManager.language))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            VStack(alignment: .leading, spacing: 6) {
                Text("category".localized(localizationManager.language))
                ZStack {
                    roundedBackground
                        .frame(height: 46)
                        .onTapGesture {
                            if !viewModel.typesArray.isEmpty {
                                haptics(.light)
                                viewModel.typeDropDownOpen.toggle()
                            }
                        }
                    typeDropDownField
                }
                .overlay(alignment: .top) {
                    dropDownMenu
                        .offset(y: 50)
                }
                .allowsHitTesting(false)
            }
            .zIndex(2.0)
            
            subTypeField
                .overlay(alignment: .top) {
                    subTypeMenu
                        .offset(y: 74)
                }
                .allowsHitTesting(false)
            
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .padding(.horizontal, 12)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 12)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}



// MARK: - Preview
struct EditCategoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditCategoryScreen(viewModel: EditCategoryViewModel(router: router, selectedAnswers: []))
    }
}



// MARK: - Components
extension EditCategoryScreen {
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
            
            Text("category".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
//                viewModel.changeBusinessType()
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
            })
        }
        .padding(.top, 16)
    }
    
    
    private var typeDropDownField: some View {
        HStack {
            if viewModel.selectedType != nil {
                WebImage(url: URL(string: viewModel.selectedType?.icon ?? ""))
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.label)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 8)
            }
            
            Text(viewModel.selectedType?.name ?? "business_type".localized(localizationManager.language))
                .foregroundStyle(viewModel.selectedType == nil ? themeManager.currentTheme.white06_darkGray06 : themeManager.currentTheme.label)
                .font(.custom(Constants.comicFont, size: viewModel.selectedType == nil ? 14 : 18))
            
            Spacer()
                .background(.black.opacity(0.001))
            
            
            Image(systemName: "chevron.down")
                .fontWeight(.semibold)
                .rotationEffect(Angle(degrees: viewModel.typeDropDownOpen ? 180 : 0))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                .animation(.smooth, value: viewModel.typeDropDownOpen)
        }
        .padding(.horizontal, 16)
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            Capsule()
                .fill(themeManager.currentTheme.darkGray05_white)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(viewModel.selectedType != nil ? .hmIndigo : themeManager.currentTheme.mediumGray_mediumGray03)
        }
    }
    
    
    private var dropDownMenu: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.typesArray) { type in
                businessTypeOption2(type: type)
            }
        }
        .background(menuBackground)
        .scaleEffect(y: viewModel.typeDropDownOpen ? 1 : 0, anchor: .top)
        .animation(.smooth(duration: 0.3), value: viewModel.typeDropDownOpen)
    }
    
    
    private func businessTypeOption2(type: TypeModel) -> some View {
        HStack {
            WebImage(url: URL(string: type.icon ?? ""))
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 22))
                .foregroundColor(viewModel.selectedType?.id == type.id ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .padding(.horizontal, 16)
            Text(type.name ?? "")
                .foregroundColor(viewModel.selectedType?.id == type.id ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 18))
            Spacer()
            
        }
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(viewModel.selectedType?.id == type.id ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
        )
        .onTapGesture {
            haptics(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.typeDropDownOpen.toggle()
            }
            viewModel.selectedType = type
        }
    }
    
    
    private var menuBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial.opacity(0.99))
//                .preferredColorScheme(.dark)
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .foregroundColor(themeManager.currentTheme.mediumGray_mediumGray03)
        }
    }
    
    
    private var subTypeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("sub_category".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            HStack {
                if viewModel.selectedType?.name == "Hotel" && viewModel.selectedSubType != nil {
                    Image("RatingStar")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.yellow)
                        .frame(width: 18, height: 16)
                        .padding(.leading, 10)
                }
                
                Text(viewModel.selectedSubType == nil ? "\(viewModel.selectedType?.name ?? "") type" : viewModel.selectedSubType?.name ?? "")
                    .foregroundStyle(viewModel.selectedSubType == nil ? themeManager.currentTheme.white06_darkGray06 : themeManager.currentTheme.label)
                    .font(.custom(Constants.comicFont, size: viewModel.selectedSubType == nil ? 14 : 18))
                
                Spacer()
                    .background(.black.opacity(0.001))
                
                
                Image(systemName: "chevron.down")
                    .fontWeight(.semibold)
                    .rotationEffect(Angle(degrees: viewModel.subTypeDropDownOpen ? 180 : 0))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .animation(.smooth, value: viewModel.subTypeDropDownOpen)
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .background(
                CapsuleBackground(
                    height: 46,
                    borderColor: viewModel.selectedSubType != nil ? .hmIndigo : themeManager.currentTheme.mediumGray_mediumGray03,
                    backgroundColor: themeManager.currentTheme.darkGray05_white
                )
            )
            .onTapGesture {
                if !viewModel.subTypesArray.isEmpty {
                    viewModel.subTypeDropDownOpen.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var subTypeMenu: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial.opacity(0.99))
//                .preferredColorScheme(.dark)
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .foregroundColor(themeManager.currentTheme.mediumGray_mediumGray03)
            VStack {
                ForEach(viewModel.subTypesArray) { subType in
                    HStack {
                        if viewModel.selectedType?.name == "Hotel" {
                            Image("RatingStar")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.yellow)
                                .frame(width: 18, height: 16)
                                .padding(.leading, 10)
                        }
                        
                        Text(subType.name ?? "")
                            .font(.custom(Constants.comicFont, size: 18))
                            .foregroundColor(viewModel.selectedSubType?.id == subType.id ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                    
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedSubType?.id == subType.id ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
                    )
                    .onTapGesture {
                        viewModel.selectedSubType = subType
                        viewModel.subTypeDropDownOpen = false
                    }
                    
                }
            }
            .padding(.vertical, 8)
        }
        .scaleEffect(y: viewModel.subTypeDropDownOpen ? 1.0 : 0.0, anchor: .top)
        .animation(.smooth(duration: 0.3), value: viewModel.subTypeDropDownOpen)
    }
}
