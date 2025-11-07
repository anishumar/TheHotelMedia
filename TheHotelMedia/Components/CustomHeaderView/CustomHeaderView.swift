//
//  CustomHeaderView.swift
//  TheHotelMedia
//
//  Created by MAC on 11/12/24.
//

import SwiftUI

struct CustomHeaderView: View {
    
    let title: String
    var systemIcon: String = "chevron.left"
    var showBackButton: Bool = true
    var onButtonPressed: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            if showBackButton {
                Image(systemName: systemIcon)
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.label)
                    .fontWeight(.bold)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .onTapGesture {
                        onButtonPressed?()
                    }
            }
            
            Text(title)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, showBackButton ? 10 : 0)
            
        }
        .padding(.top, 12)
    }
}

#Preview {
    CustomHeaderView(title: "Settings")
}
