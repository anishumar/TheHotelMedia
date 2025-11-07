//
//  AllAmenitiesView.swift
//  TheHotelMedia
//
//  Created by MAC on 21/02/25.
//

import SwiftUI

struct AllAmenitiesView: View {
    
    @StateObject var viewModel: AllAmenitiesViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let verticalGrid: [GridItem] = [
        GridItem(.flexible(), spacing: 8, alignment: .leading),
        GridItem(.flexible(), spacing: 8, alignment: .leading)
//        GridItem(.flexible(), spacing: 10, alignment: .leading)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 2)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: Constants.screenWidth * 0.18, height: 4)
            
            Text("Amenities")
                .withComicFont(16, color: themeManager.currentTheme.label)
            
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(0..<viewModel.sortedAmenties.count) { index in
                        let array = viewModel.sortedAmenties[index]
                        if !array.isEmpty {
                            VStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(themeManager.currentTheme.white03_darkGray03)
                                    .frame(height: 1)
                                headerTitleView(icon: "Check-in-out", title: array[0].category ?? "Uncategoried")
                                
                                LazyVGrid(columns: verticalGrid) {
                                    ForEach(array) { amenity in
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .fill(.white)
                                                    .padding(2)
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.hmIndigo)
                                            }
                                            .frame(maxWidth: 16, maxHeight: 16)
                                            
                                            
                                            Text(amenity.name ?? "")
                                                .withComicFont(12, color: themeManager.currentTheme.white06_darkGray06)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.darkGray_white)
        
    }
}


// MARK: - Components
extension AllAmenitiesView {
    private func headerTitleView(icon: String, title: String) -> some View {
        HStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            
            Text(title)
                .withComicFont(16, color: themeManager.currentTheme.white_darkGray)
            
            Spacer()
        }
    }
}
