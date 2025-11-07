//
//  RoomCardView.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct RoomCardView: View {
    
    let room: AvailableRoom
    let verticalGrid: [GridItem] = [
        GridItem(.flexible(), spacing: 8, alignment: .leading),
        GridItem(.flexible(), spacing: 8, alignment: .leading),
        GridItem(.flexible(), spacing: 8, alignment: .leading)
    ]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            CustomRadiusRectangle(topLeadingRadius: 14, topTrailingRadius: 14, bottomTrailingRadius: 8, bottomLeadingRadius: 8)
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(height: Constants.screenHeight * 0.19)
                .frame(maxWidth: .infinity)
                .overlay {
                    WebImage(url: URL(string: room.cover?.sourceURL ?? ""))
                        .resizable()
                        .scaledToFill()
                        .allowsHitTesting(false)
                }
                .clipShape(CustomRadiusRectangle(topLeadingRadius: 14, topTrailingRadius: 14, bottomTrailingRadius: 8, bottomLeadingRadius: 8))
            
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(.hmDarkestGray.opacity(0.6))
                            Circle()
                                .stroke(lineWidth: 0.85)
                                .fill(.hmDarkerGray)
                            Image("Bed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        .frame(width: 28, height: 28)
                        
                        Text(room.title ?? "")
                            .withComicFont(16, color: themeManager.currentTheme.label)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        
                        Text("₹\(String(format: "%.0f", room.pricePerNight ?? 0))/")
                            .withComicFont(16, color: themeManager.currentTheme.label)
                        Text("Night")
                            .withComicFont(16, color: themeManager.currentTheme.white06_darkGray06)
                        
                    }
                }
                
                
                Text(room.description ?? "")
                    .withComicFont(12, color: themeManager.currentTheme.white08_darkGray08)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                LazyVGrid(columns: verticalGrid, alignment: .leading) {
                    if let amenitiesRef = room.amenitiesRef {
                        if amenitiesRef.count > 6 {
                            ForEach(0..<5) { index in
                                amenityView(title: amenitiesRef[index].name ?? "")
                            }
                            
                            moreView(count: amenitiesRef.count - 5)
                            
                        } else {
                            ForEach(0..<amenitiesRef.count) { index in
                                amenityView(title: amenitiesRef[index].name ?? "")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineWidth: 2)
                .fill(themeManager.currentTheme.mediumGray_hmIndigo)
        }
        .background(themeManager.currentTheme.darkGray05_white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(2)
    }
}

extension RoomCardView {
    private func amenityView(title: String) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(.white)
                    .padding(2)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.hmIndigo)
            }
            .frame(width: 16, height: 16)
            
            Text(title)
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
                .lineLimit(1)
        }
    }
    
    
    private func moreView(count: Int) -> some View {
        HStack(spacing: 4) {
            Image("Plus")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .scaledToFill()
                .padding(2.5)
                .frame(width: 16, height: 16)
            
            Text("\(count) more")
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
        }
    }
}
