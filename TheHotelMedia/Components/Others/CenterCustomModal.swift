//
//  CenterCustomModal.swift
//  TheHotelMedia
//
//  Created by MAC on 14/11/24.
//

import SwiftUI

struct CenterCustomModal: View {
    
    var title: String = "Upload"
    var leftButtonImage: String = "CameraBlue"
    var rightButtonImage: String = "GalleryBlue"
    var leftButtonTitle: String = "Camera"
    var rightButtonTitle: String = "Photos"
    var onLeftButtonPressed: (() -> Void)? = nil
    var onRightButtonPressed: (() -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        VStack(spacing: 24) {
            Text(title)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
            
            if themeManager.darkThemeActive {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [.black, .hmDarkerGray, .white.opacity(0.7), .hmDarkerGray, .black], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 225, height: 1.2)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.6))
                    .frame(width: 225, height: 1.2)
            }
            
            
            HStack(spacing: 40) {
                VStack {
                    Image(leftButtonImage)
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 58))
                        .foregroundColor(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                    
                    Text(leftButtonTitle)
                        .withComicFont(16, color: themeManager.currentTheme.label)
                        .frame(maxWidth: 70)
                }
                .background(Color.black.opacity(0.001))
                .onTapGesture {
                    onLeftButtonPressed?()
                }
                
                if themeManager.darkThemeActive {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(colors: [.black, .hmDarkerGray, .white.opacity(0.7), .hmDarkerGray, .black], startPoint: .top, endPoint: .bottom))
                        .frame(width: 1.2, height: 87)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.white.opacity(0.6))
                        .frame(width: 1.2, height: 87)
                    
                }
                
                VStack {
                    Image(rightButtonImage)
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 58))
                        .foregroundColor(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                    
                    Text(rightButtonTitle)
                        .withComicFont(16, color: themeManager.currentTheme.label)
                        .frame(maxWidth: 70)
                }
                .background(Color.black.opacity(0.001))
                .onTapGesture {
                    onRightButtonPressed?()
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.black08_white05)
        )
    }
}

#Preview {
    CenterCustomModal()
}
