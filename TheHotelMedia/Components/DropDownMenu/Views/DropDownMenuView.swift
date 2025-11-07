//
//  DropDownMenuView.swift
//  HotelMedia
//
//  Created by MAC on 23/08/24.
//

import SwiftUI

struct DropDownMenuView: View {
    
    @StateObject var viewModel: DropDownMenuViewModel
    var fontSize: CGFloat = 14
    var selectedFontSize: CGFloat = 18
    var titleFontSize: CGFloat = 14
    var optionFontSize: CGFloat = 18
    var borderColor: Color = .hmDarkerGray
    var isBold: Bool = false
    var onSelected: ((String) -> Void)
    
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

// MARK: - Preview
struct DropDownMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DropDownMenuView(
            viewModel: DropDownMenuViewModel(
                model: DropDownModel(id: "", answer: [], question: "")
            )) { selectedOption in
            }
    }
}


// MARK: - Components

extension DropDownMenuView {
    private var dropDownField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.model.question)
                .font(.custom(Constants.comicFont, size: titleFontSize))
                .foregroundColor(isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06)
                .multilineTextAlignment(.leading)
                .lineLimit(0)
            HStack {
                
                Text(viewModel.selectedOption == nil ? viewModel.model.question.replacingOccurrences(of: "?", with: "") : viewModel.selectedOption!)
                    .foregroundStyle(viewModel.selectedOption == nil ? isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06 : themeManager.currentTheme.label)
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
                ForEach(viewModel.model.answer, id: \.self) { item in
                    HStack {
                        Text(item)
                            .font(.custom(Constants.comicFont, size: optionFontSize))
                            .foregroundColor(viewModel.selectedOption == item ?(isBold ? .white.opacity(0.8) : .white.opacity(0.6)): (isBold ? themeManager.currentTheme.white08_darkGray08 : themeManager.currentTheme.white06_darkGray06))
                            .padding(.horizontal, 16)
                        
                        Spacer()
                            
                            
                    }
                    
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedOption == item ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
                    )
                    .onTapGesture {
                        viewModel.selectedOption = item
                        viewModel.dropDownOpen = false
                        onSelected(item)
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
