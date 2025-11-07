//
//  DropDownMenuView2.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct DropDownMenuView2: View {
    
    @StateObject var viewModel: DropDownMenuViewModel2
    var fontSize: CGFloat = 14
    var selectedFontSize: CGFloat = 18
    var titleFontSize: CGFloat = 14
    var optionFontSize: CGFloat = 18
    var borderColor: Color = .hmDarkerGray
    var selectedColor: Color? = nil
    var isBold: Bool = false
    var onSelected: ((String) -> Void)
    var isOpen: ((Bool) -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            dropDownField
                .overlay(
                    dropDownMenu
                    , alignment: .top
                )
        }
    }
}


// MARK: - Components

extension DropDownMenuView2 {
    private var dropDownField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.model.question)
                .font(.custom(Constants.comicFont, size: titleFontSize))
                .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                .multilineTextAlignment(.leading)
                .lineLimit(0)
            HStack {
                
                Text(viewModel.selectedOption == nil ? viewModel.model.question.replacingOccurrences(of: "?", with: "") : viewModel.selectedOption!)
                    .foregroundStyle(
                        viewModel.selectedOption == nil ? isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06 : selectedColor == nil ? themeManager.currentTheme.label : selectedColor!
                    )
                    .font(.custom(Constants.comicFont, size: viewModel.selectedOption == nil ? fontSize : selectedFontSize))
                
                Spacer()
                    .background(.black.opacity(0.001))
                
                
                Image(systemName: "chevron.down")
                    .fontWeight(.semibold)
                    .rotationEffect(Angle(degrees: viewModel.dropDownOpen ? 180 : 0))
                    .foregroundStyle(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                    .animation(.smooth, value: viewModel.dropDownOpen)
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .background(
                CapsuleBackground(
                    height: 46,
                    borderColor: borderColor,
                    backgroundColor: themeManager.currentTheme.darkGray05_white
                )
            )
            .onTapGesture {
                viewModel.dropDownOpen.toggle()
                isOpen?(viewModel.dropDownOpen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dropDownMenu: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial.opacity(0.99))
//                .preferredColorScheme(.dark)
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .foregroundColor(borderColor)
            VStack {
                ForEach(viewModel.model.answer, id: \.option) { item in
                    HStack {
                        if let icon = item.icon, !icon.isEmpty, let url = URL(string: icon) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(width: optionFontSize, height: optionFontSize)
                        }
                        Text(item.option)
                            .font(.custom(Constants.comicFont, size: optionFontSize))
                            .foregroundColor(viewModel.selectedOption == item.option ?(isBold ? .white.opacity(0.8) : .white.opacity(0.6)): (isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06))
                            .padding(.horizontal, 16)
                        
                        Spacer()
                            
                            
                    }
                    
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedOption == item.option ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
                    )
                    .onTapGesture {
                        viewModel.selectedOption = item.option
                        viewModel.dropDownOpen = false
                        onSelected(item.option)
                        isOpen?(viewModel.dropDownOpen)
                    }
                    
                }
            }
            .padding(.vertical, 8)
            
        }
            .frame(maxWidth: .infinity)
            .scaleEffect(y: viewModel.dropDownOpen ? 1 : 0, anchor: .top)
            .offset(y: 75)
            .animation(.easeIn(duration: 0.2), value: viewModel.dropDownOpen)
            .padding(.vertical, 8)
    }
}

