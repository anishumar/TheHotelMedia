//
//  UserSelectionView.swift
//  HotelMedia
//
//  Created by MAC on 07/02/25.
//

import SwiftUI
import SwiftfulRouting
import SDWebImageSwiftUI

struct UserSelectionView: View {
    
    @StateObject var viewModel: UserSelectionViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            
            searchField
                .padding(.vertical, 10)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.searchProfileData) { profile in
                        userRow(profile: profile)
                            .onAppear {
                                if let lastProfile = viewModel.searchProfileData.last {
                                    if lastProfile.id == profile.id {
                                        viewModel.profileDataPageNo += 1
                                        viewModel.getProfileResults(query: viewModel.searchFieldText, resetData: false)
                                    }
                                }
                            }
                    }
                    
                    if viewModel.searchProfileData.isEmpty && !viewModel.showLoadingIndicator {
                        if viewModel.searchFieldText.isEmpty {
                            Text("Type to search users")
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                                .padding(.top, 40)
                        } else {
                            Text("No users found")
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                                .padding(.top, 40)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
            }
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            if viewModel.showLoadingIndicator {
                ProgressView()
                    .tint(themeManager.currentTheme.label)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .onTapGesture {
                    dismiss()
                }
            
            Text("Tag People")
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .padding(.leading, 10)
            
            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            TextField("Search", text: $viewModel.searchFieldText)
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(themeManager.currentTheme.label)
                .accentColor(.indigo)
            
            if !viewModel.searchFieldText.isEmpty {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .onTapGesture {
                        viewModel.searchFieldText = ""
                    }
            }
        }
        .padding(12)
        .background(themeManager.currentTheme.darkGray05_white)
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    private func userRow(profile: SearchProfileData) -> some View {
        HStack(spacing: 12) {
            WebImage(url: URL(string: profile.profilePic?.small ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image("Avatar")
                    .resizable()
                    .scaledToFill()
            }
                .scaledToFill()
                .frame(width: 45, height: 45)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.username ?? "")
                    .font(.custom(Constants.comicBold, size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                
                if let name = profile.name, !name.isEmpty {
                    Text(name)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let username = profile.username {
                viewModel.onUserSelected?(profile.id, username)
                dismiss()
            }
        }
    }
}
