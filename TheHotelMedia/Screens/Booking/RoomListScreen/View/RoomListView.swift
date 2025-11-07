//
//  RoomListScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct RoomListView: View {
    
    @StateObject var viewModel: RoomListViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomHeaderView(title: "Plan Details".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                businessHeaderView
                    .padding(2)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        fromDateField
                        toDateField
                    }
                    
                    
                    GrayTextField(
                        textfieldText: .constant(viewModel.bookingDetail.toShowGuestString),
                        title: "Guest".localized(localizationManager.language),
                        placeholder: "Guest".localized(localizationManager.language),
                        leftIcon: "Key-Heart",
                        defaultBorderColor: .hmDarkerGray,
                        rightIcon: .constant(nil)
                    )
                    .overlay {
                        Rectangle()
                            .fill(.black.opacity(0.001))
                    }
                }
                
                if viewModel.checkInData.availableRooms?.isNotEmpty ?? false {
                    Text("Available Rooms".localized(localizationManager.language))
                        .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVStack(spacing: 10) {
                        if let rooms = viewModel.checkInData.availableRooms {
                            ForEach(rooms) { room in
                                RoomCardView(room: room)
                                    .onTapGesture {
                                        viewModel.showRoomDetailScreen(id: room.id ?? "", price: room.pricePerNight ?? 0)
                                    }
                            }
                        }
                    }
                } else {
                    EmptyScreenView(image: "Hotel2", title: "No rooms available".localized(localizationManager.language))
                }
                
            }
            .overlay {
                CustomProgressView(showIndicator: $viewModel.showLoadingindicator)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
    }
}


// MARK: - Components
extension RoomListView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.profileData.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.profileData.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.profileData.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.profileData.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    
                    if let rating = viewModel.profileData.businessProfileRef?.rating {
                        if rating > 0 {
                            HStack(spacing: 2) {
                                Text("-")
                                    .foregroundColor(.white.opacity(0.8))
                                Image("RatingStar")
                                    .renderingMode(.template)
                                    .foregroundColor(rating.getStarColor())
                                    .frame(height: 12)
                                
                                Text("\(String(format: "%.1f", rating))")
                            }
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(rating.getStarColor())
                        }
                    }
                }
                
                
                Text(viewModel.bookingDetail.toShowAddressString)
                    .withComicFont(11, color: .white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.5))
            }
        )
    }
    
    
    private var fromDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Check-in".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.bookingDetail.fromDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var toDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Check-out".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.bookingDetail.toDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
    

