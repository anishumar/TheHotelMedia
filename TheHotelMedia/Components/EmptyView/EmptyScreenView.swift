//
//  EmptyScreenView.swift
//  TheHotelMedia
//
//  Created by MAC on 03/10/24.
//

import SwiftUI

struct EmptyScreenView: View {
    
    var image: String
    var title: String
    var subtitle: String? = nil
    var buttonTitle: String? = nil
    var height: CGFloat = 0.4
    var titleMaxWidth: CGFloat = 0.6
    var subTitleMaxWidth: CGFloat = 0.6
    var color: Color? = nil
    var onPressedButton: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 80))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.custom(Constants.comicFont, size: 18))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: UIScreen.main.bounds.width * titleMaxWidth)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: UIScreen.main.bounds.width * subTitleMaxWidth)
                    }
                    
                    if let buttonTitle {
                        Button {
                            onPressedButton?()
                        } label: {
                            Text(buttonTitle)
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(.hmIndigo)
                                .multilineTextAlignment(.center)
                        }

                    }
                }
                
            }
        }
        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * height, maxHeight: .infinity)
        .background(color == nil ? themeManager.currentTheme.backgroundColor : color!)
    }
}

#Preview {
    EmptyScreenView(image: "CategoryIcon", title: "Some title", subtitle: "This is some subtile for this title. This is some subtile for this title.")
}
