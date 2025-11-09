//
//  CollaborateView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/02/25.
//

import SwiftUI
import SDWebImageSwiftUI


struct CollaborateView: View {
    
    @StateObject var viewModel: CollaborateViewModel
    @Binding var selectedProfiles: [SearchProfile]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            searchField
            selectedProfileSection
                .frame(height: viewModel.selectedProfiles.isEmpty ? 0 : 70)
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.profiles) { profile in
                            profileRowView(profile: profile)
                                .onTapGesture {
                                    withAnimation(.smooth) {
                                        viewModel.didTapProfileView(profile: profile)
                                    }
                                }
                                .onAppear {
                                    if let lastProfile = viewModel.profiles.last {
                                        if lastProfile.id == profile.id {
                                            viewModel.pageNumber += 1
                                            viewModel.isPagination = true
                                            viewModel.getProfiles(pageNo: viewModel.pageNumber)
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 60)
        .clipped()
        .background(
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
        )
        .onChange(of: selectedProfiles, perform: { value in
            viewModel.selectedProfiles = value
        })
        .overlay(
            header
                .padding(.bottom, 4)
                .padding(.horizontal, 12)
                .background(
                    themeManager.currentTheme.backgroundColor
                )
            , alignment: .top
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview
struct CollaborateView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        CollaborateView(viewModel: CollaborateViewModel(router: router), selectedProfiles: .constant([]))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension CollaborateView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    dismiss.callAsFunction()
                }
            
            Text("collaborate".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                selectedProfiles = viewModel.selectedProfiles
                dismiss.callAsFunction()
            }, label: {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
                    .opacity(viewModel.selectedProfiles.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.selectedProfiles.isEmpty)
        }
        .padding(.top, 16)
    }
    
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            TextField(
                "",
                text: $viewModel.searchFieldText,
                prompt: Text("search".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            )
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity)
            
        }
        .foregroundStyle(.white.opacity(0.6))
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            CapsuleBackground(backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private var selectedProfileSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.selectedProfiles) { profile in
                    profileImageView(profile: profile)
                        .overlay(
                            xmarkButton
                                .frame(width: 24, height: 24)
                                .background(
                                    Color.black.opacity(0.001)
                                )
                                .onTapGesture {
                                    withAnimation(.smooth) {
                                        viewModel.didDeselectProfile(profile: profile)
                                    }
                                }
                                .offset(x: 4, y: -4)
                            , alignment: .topTrailing
                        )
                }
            }
            .animation(.none, value: viewModel.selectedProfiles)
        }
    }
    
    
    private func profileRowView(profile: SearchProfile) -> some View {
        HStack(spacing: 15) {
            WebImage(url: URL(string:profile.accountType == "business" ? profile.businessProfileRef?.profilePic?.small ?? "" : profile.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
            })
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(profile.accountType == "individual" ? profile.name ?? "" : profile.businessProfileRef?.name ?? "")
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                    
                    if profile.role == "official" {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .foregroundColor(.hmIndigo)
                            .frame(width: 16, height: 16)
                    }
                }
                
                if profile.accountType == "individual" {
                    Text(profile.username ?? "")
                        .font(.custom(Constants.comicFont, size: 11))
                        .foregroundColor(themeManager.currentTheme.white04_darkGray07)
                        .lineLimit(1)
                }
                
                if profile.accountType == "business" {
                    HStack(spacing: 2) {
                        WebImage(url: URL(string: profile.businessProfileRef?.businessTypeRef?.icon ?? ""))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                        
                        Text(profile.businessProfileRef?.businessTypeRef?.name ?? "")
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(themeManager.currentTheme.white04_darkGray07)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        CapsuleBackground(height: 20, borderColor: themeManager.currentTheme.mediumGray_hmIndigo05, backgroundColor: themeManager.currentTheme.darkGray05_hmIndigo02)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 30)
            .frame(height: 46, alignment: .top)
            
            Spacer()
            
            // Selection indicator - C-shaped icon
            selectionIndicator(isSelected: profile.isSelected ?? false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 58, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.black09_white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(profile.isSelected ?? false ? themeManager.currentTheme.hmIndigo_hmIndigo05 : Color.clear, lineWidth: 1.5)
                )
        )
    }
    
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 12, height: 12)
                    )
            } else {
                Circle()
                    .stroke(themeManager.currentTheme.hmIndigo_hmIndigo05, lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.trailing, 8)
    }
    
    
    private var xmarkButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 16)
            
            Image(systemName: "xmark")
                .renderingMode(.template)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    
    private func profileImageView(profile: SearchProfile) -> some View {
        VStack {
            WebImage(url: URL(string:profile.accountType == "business" ? profile.businessProfileRef?.profilePic?.small ?? "" : profile.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60)
                    .clipShape(Circle())
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60)
                    .clipShape(Circle())
            })
            
            Text(profile.accountType == "individual" ? profile.name ?? "" : profile.businessProfileRef?.name ?? "")
                .font(.custom(Constants.comicFont, size: 9))
                .foregroundColor(themeManager.currentTheme.label)
        }
    }
}

