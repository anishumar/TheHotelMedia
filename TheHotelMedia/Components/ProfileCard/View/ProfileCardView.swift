//
//  ProfileCard.swift
//  TheHotelMedia
//
//  Created by MAC on 07/10/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileCardView: View {
    
    @StateObject var viewModel: ProfileCardViewModel
    var showBusinessTypeDetail: Bool = true
    var showHeartIcon: Bool = false
    var onEllipsisButtonPressed: ((String) -> Void)? = nil
//    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            
            if viewModel.accountType == "individual" {
                individualProfilePic
            } else {
                businessProfilePic
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(viewModel.name)
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    if viewModel.role == "official" {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .foregroundColor(.hmIndigo)
                            .frame(width: 16, height: 16)
                    }
                    
                }
                
                
                if viewModel.accountType == "business" && showBusinessTypeDetail {
                    businessTypeView
                }
                
                // When business type view is hidden showing business profile username.
                if viewModel.accountType == "business" && !showBusinessTypeDetail {
                    Text(viewModel.username)
                        .withComicFont(11, color: themeManager.currentTheme.white06_darkGray06)
                }
                
                if showBusinessTypeDetail || viewModel.accountType == "individual" {
                    Text(viewModel.accountType == "individual" ? viewModel.username : viewModel.addressString)
                        .withComicFont(11, color: themeManager.currentTheme.white06_darkGray06)
                }
                
                
                
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
                    if let id = viewModel.profile?.id {
                        onEllipsisButtonPressed?(id)
                    } else if let id = viewModel.taggedProfile?.id {
                        onEllipsisButtonPressed?(id)
                    }
                }
        }
        .onAppear {
            if let profile = viewModel.profile {
                if let accountType = profile.accountType {
                    viewModel.accountType = accountType
                    
                    if accountType == "individual" {
                        viewModel.name = profile.name ?? ""
                        viewModel.username = profile.username ?? ""
                        viewModel.profilePic = profile.profilePic?.small ?? ""
                        
                    } else if accountType == "business" {
                        viewModel.name = profile.businessProfileRef?.name ?? ""
                        viewModel.profilePic = profile.businessProfileRef?.profilePic?.small ?? ""
                        
                        if let address = profile.businessProfileRef?.address {
                            viewModel.addressString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                        }
                        
                        viewModel.businessType = profile.businessProfileRef?.businessTypeRef?.name ?? ""
                        viewModel.businessTypeIcon = profile.businessProfileRef?.businessTypeRef?.icon ?? ""
                    }
                }
            }
            
            if let taggedProfile = viewModel.taggedProfile {
                if let accountType = taggedProfile.accountType {
                    viewModel.accountType = accountType
                    
                    if accountType == "individual" {
                        viewModel.name = taggedProfile.name ?? ""
                        viewModel.username = taggedProfile.username ?? ""
                        viewModel.profilePic = taggedProfile.profilePic?.small ?? ""
                        
                    } else if accountType == "business" {
                        viewModel.name = taggedProfile.businessProfileRef?.name ?? ""
                        viewModel.profilePic = taggedProfile.businessProfileRef?.profilePic?.small ?? ""
                        
                        if let address = taggedProfile.businessProfileRef?.address {
                            viewModel.addressString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                        }
                        
                        if let businessTypeRef = taggedProfile.businessProfileRef?.businessTypeRef {
                            viewModel.businessType = businessTypeRef.name ?? ""
                            viewModel.businessTypeIcon = businessTypeRef.icon ?? ""
                        }
                        
                    }
                }
            }
            
        }
    }
}

#Preview {
    VStack {
        ProfileCardView(viewModel: ProfileCardViewModel(profile: SearchProfileData(id: "", accountType: "individual", profilePic: nil, username: "", name: "Optimus Prime", role: "", businessProfileRef: nil)))
    }
    .frame(maxHeight: .infinity)
    .background(.black)
}


// MARK: - Components
extension ProfileCardView {
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
                WebImage(url: URL(string: viewModel.profilePic), content: { image in
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
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    if showHeartIcon {
                        Image("heartfill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 9, height: 9)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.backgroundColor)
                                    .frame(width: 18, height: 18)
                            )
                    }
                }
            }
    }
    
    
    private var individualProfilePic: some View {
        Circle()
            .fill(.black)
            .frame(width: 42, height: 42)
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic), content: { image in
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
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    if showHeartIcon {
                        Image("heartfill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 9, height: 9)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.backgroundColor)
                                    .frame(width: 18, height: 18)
                            )
                    }
                }
            }
    }
    
    
    private var businessTypeView: some View {
        HStack {
            WebImage(url: URL(string: viewModel.businessTypeIcon))
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 12, height: 12)
            Text(viewModel.businessType)
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
                
                
        }
        .padding(.horizontal, 6)
        .background(
            CapsuleBackground(height: 18, borderColor: themeManager.currentTheme.mediumGray_hmIndigo05, backgroundColor: themeManager.currentTheme.darkGray05_hmIndigo02)
        )
    }
}
