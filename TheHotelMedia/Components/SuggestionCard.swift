//
//  SuggestionCard.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import SwiftUI

struct SuggestionCard: View {
    
    var suggestion: ReviewedBusinessProfileRef
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedCross: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            BusinessProfilePicView(stringURL: suggestion.profilePic?.medium ?? "", dimension: Constants.screenWidth * 0.2, border: 6)
            VStack(spacing: 2) {
                Text(suggestion.name ?? "")
                    .withComicFont(14, color: themeManager.currentTheme.label)
                    .lineLimit(1)
                
                BusinessTypeAndRatingView(rating: suggestion.rating ?? 0, type: suggestion.businessTypeRef?.name ?? "")
                    .withComicFont(11, color: themeManager.currentTheme.white04_darkGray07)
                
                Text("\(suggestion.address?.street ?? ""), \(suggestion.address?.city ?? ""), \(suggestion.address?.state ?? ""), \(suggestion.address?.zipCode ?? ""), \(suggestion.address?.country ?? "") ")
                    .withComicFont(11, color: themeManager.currentTheme.white04_darkGray07)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .frame(width: Constants.screenWidth * 0.65)
        .background(
            CustomShape4()
                .fill(themeManager.currentTheme.black09_white)
                .drawingGroup()
                
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .drawingGroup()
        )
        .onTapGesture {
            onPressedProfile?(suggestion.userID ?? "")
        }
        .overlay(
            crossButton(suggestionID: suggestion.id ?? "")
                .drawingGroup()
            , alignment: .topTrailing
        )
    }
}

#Preview {
    SuggestionCard(suggestion: ReviewedBusinessProfileRef(id: nil, profilePic: nil, name: nil, address: nil, businessTypeRef: nil, businessSubtypeRef: nil, coverImage: nil, userID: nil, rating: nil))
}

// MARK: -  Components
extension SuggestionCard {
    private func crossButton(suggestionID: String) -> some View {
        Button(action: {
            onPressedCross?(suggestionID)
        }, label: {
            Circle()
                .fill(themeManager.currentTheme.black09_white)
                .frame(width: 28)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
                )
        })
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
}
