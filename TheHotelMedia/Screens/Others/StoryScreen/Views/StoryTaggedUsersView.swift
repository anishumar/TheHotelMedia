//
//  StoryTaggedUsersView.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct StoryTaggedUsersView: View {
    
    @StateObject var viewModel: StoryTaggedUsersViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Header
            HStack {
                Text("tagged_people".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 18))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.label)
                        .padding(8)
                        .background(themeManager.currentTheme.label.opacity(0.1))
                        .clipShape(Circle())
                })
            }
            .padding()
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.taggedUsers.isEmpty {
                Spacer()
                Text("no_tagged_users".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label.opacity(0.6))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.taggedUsers, id: \.id) { user in
                            HStack(spacing: 12) {
                                WebImage(url: URL(string: user.profilePic?.small ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image("user_placeholder")
                                        .resizable()
                                        .scaledToFill()
                                }
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.username ?? "")
                                        .font(.custom(Constants.comicBold, size: 14))
                                        .foregroundColor(themeManager.currentTheme.label)
                                    
                                    if let name = user.businessProfileRef?.name ?? user.name, !name.isEmpty {
                                        Text(name)
                                            .font(.custom(Constants.comicFont, size: 12))
                                            .foregroundColor(themeManager.currentTheme.label.opacity(0.6))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                                // Small delay to allow sheet to dismiss before pushing (optional but often smoother)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    viewModel.navigateToProfile(user: user)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}
