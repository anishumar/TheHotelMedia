//
//  SelectBusinessTypeView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import ActivityIndicatorView
import SDWebImageSwiftUI

// MARK: - Enum -> BusinessType
enum BusinessType: String {
    case hotel = "Hotels"
    case bar = "Bars/Pubs"
    case homestay = "Home Stays"
    case banquet = "Marriage Banquets"
    case restaurant = "Restaurants"
}

// MARK: - Main Structure
struct SelectBusinessTypeView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: SelectBusinessTypeViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            VStack(spacing: 40) {
                logo
                VStack(spacing: 20) {
                    title
                    VStack(alignment: .leading) {
                        Text("business_type".localized(localizationManager.language).capitalized)
                            .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                            .font(.custom(Constants.comicFont, size: 14))
                        
                        ZStack {
                            roundedBackground
                                .frame(height: 46)
                                .onTapGesture {
                                    if !viewModel.typesArray.isEmpty {
                                        haptics(.light)
                                        viewModel.dropDownOpen.toggle()
                                    }
                                }
                            dropDownField
                        }
                        dropDownMenu
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            bottomButtonSection
            
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getBusinessTypes()
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

struct SelectBusinessTypeView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SelectBusinessTypeView(viewModel: SelectBusinessTypeViewModel(router: router))
    }
}


// MARK: - Components
extension SelectBusinessTypeView {
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
                .padding(.top, UIScreen.main.bounds.height < 670 ? 20 : 100)
        }
    }
    
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("select_business_type".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            Capsule()
                .fill(themeManager.currentTheme.darkGray05_white)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(viewModel.businessType != nil ? .hmIndigo : .hmDarkerGray)
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
            if viewModel.selectedType != nil {
                WebImage(url: URL(string: viewModel.selectedType?.icon ?? ""))
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 8)
            }
            
            Text(viewModel.selectedType?.name ?? "business_type".localized(localizationManager.language))
                .foregroundStyle(viewModel.businessType == nil ? themeManager.currentTheme.white06_darkGray06 : themeManager.currentTheme.label)
                .font(.custom(Constants.comicFont, size: viewModel.businessType == nil ? 14 : 18))
            
            Spacer()
                .background(.black.opacity(0.001))
                
            
            Image(systemName: "chevron.down")
                .fontWeight(.semibold)
                .rotationEffect(Angle(degrees: viewModel.dropDownOpen ? 180 : 0))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .padding(.horizontal, 16)
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
                .foregroundStyle(viewModel.selectedType?.id == type.id ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
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
                viewModel.dropDownOpen.toggle()
            }
            viewModel.selectedType = type
        }
    }
    
    
    private var dropDownMenu: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.typesArray) { type in
                businessTypeOption2(type: type)
            }
        }
        .background(menuBackground)
        .scaleEffect(y: viewModel.dropDownOpen ? 1 : 0, anchor: .top)
        .animation(.smooth(duration: 0.3), value: viewModel.dropDownOpen)
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
                            guard let _ = viewModel.selectedType else { return }
                            viewModel.showNextScreen()
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}
