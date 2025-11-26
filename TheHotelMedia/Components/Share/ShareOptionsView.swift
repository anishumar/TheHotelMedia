//
//  ShareOptionsView.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI

struct ShareOptionsView: View {
    
    var title: String = "Share Post"
    var onShareToChatPressed: (() -> Void)? = nil
    var onShareLinkPressed: (() -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.hmIndigo.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "message.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.hmIndigo)
                    }
                    Text("Share to Chat")
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.label)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 70)
                }
                .background(Color.black.opacity(0.001))
                .onTapGesture {
                    onShareToChatPressed?()
                }
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.hmIndigo.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "link")
                            .font(.system(size: 24))
                            .foregroundColor(.hmIndigo)
                    }
                    Text("Share Link")
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.label)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 70)
                }
                .background(Color.black.opacity(0.001))
                .onTapGesture {
                    onShareLinkPressed?()
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
    ShareOptionsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LocalizationManager.shared)
}

