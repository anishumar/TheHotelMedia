//
//  SuggestionProfile.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct SuggestionProfile: View {
    
    @StateObject var viewModel: SuggestionProfileViewModel
    var onEllipsisButtonPressed: ((String) -> Void)? = nil
//    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            
            businessProfilePic
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(viewModel.suggestion.name ?? "")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
//                    if viewModel.role == "official" {
//                        Image(systemName: "checkmark.seal.fill")
//                            .resizable()
//                            .foregroundColor(.hmIndigo)
//                            .frame(width: 16, height: 16)
//                    }
                    
                }
                
                
                businessTypeView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            CustomShape3()
                .fill(themeManager.currentTheme.black09_white)
        )
        .padding(2.5)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
//        .onTapGesture {
//            onPressedProfile?(viewModel.taggedProfile?.id ?? "")
//        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(themeManager.currentTheme.black09_white)
                .frame(width: 26)
                .overlay {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(themeManager.currentTheme.white_hmIndigo)
                                .frame(width: 3)
                        }
                    }
                }
                .offset(x: -5, y: 5)
                .onTapGesture {
                    onEllipsisButtonPressed?(viewModel.suggestion.userID ?? "")
                }
        }
    }
}

#Preview {
    SuggestionProfile(viewModel: SuggestionProfileViewModel(suggestion: Suggestion(id: nil, rating: nil, profilePic: nil, name: nil, address: nil, businessTypeRef: nil, businessSubtypeRef: nil, userID: nil)))
}


// MARK: - Components
extension SuggestionProfile {
    private var businessProfilePic: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 42, height: 42)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 39)
            )
            .overlay(
                WebImage(url: URL(string: viewModel.suggestion.profilePic?.small ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                })
            )
    }
    
    
    private var individualProfilePic: some View {
        Circle()
            .fill(.black)
            .frame(width: 42, height: 42)
            .overlay(
                WebImage(url: URL(string: viewModel.suggestion.profilePic?.small ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 42, height: 42)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 42, height: 42)
                })
                
            )
    }
    
    
    private var businessTypeView: some View {
        HStack {
            WebImage(url: URL(string: viewModel.suggestion.businessTypeRef?.icon ?? ""))
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 12, height: 12)
            Text(viewModel.suggestion.businessTypeRef?.name ?? "")
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
                
                
        }
        .padding(.horizontal, 6)
        .background(
            CapsuleBackground(height: 18, borderColor: themeManager.currentTheme.mediumGray_hmIndigo05, backgroundColor: themeManager.currentTheme.darkGray05_hmIndigo02)
        )
    }
}
