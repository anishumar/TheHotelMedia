//
//  ImageLoaderView.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageLoaderView: View {
    
    var urlString: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Rectangle()
            .fill(themeManager.currentTheme.darkGray06_darkGray008)
            .overlay {
                WebImage(url: URL(string: urlString))
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            }
            .clipped()
    }
}
