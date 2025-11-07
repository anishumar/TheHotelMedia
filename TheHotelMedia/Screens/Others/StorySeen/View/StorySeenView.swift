//
//  StorySeenView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI

struct StorySeenView: View {
    
    @StateObject var viewModel: StorySeenViewModel
    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.ignoresSafeArea()
            
            if #available(iOS 16.4, *) {
                customBackground
            } else {
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack {
                headerView
                    .padding(.horizontal, 12)
                ScrollView(.vertical, showsIndicators: false) {
                    if viewModel.selectedTab == "views" {
                        LazyVStack {
                            ForEach(viewModel.viewedByProfilesArray) { profile in
                                ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), showBusinessTypeDetail: false, onEllipsisButtonPressed: { _ in
                                    viewModel.selectedProfile = profile
                                    withAnimation(.easeInOut) {
                                        viewModel.showProfileOptions = true
                                    }
                                })
                                .onTapGesture {
                                    onPressedProfile?(profile.id)
                                }
                                .onAppear {
                                    if let lastProfile = viewModel.viewedByProfilesArray.last {
                                        if lastProfile.id == profile.id {
                                            viewModel.storyViewsPageNo += 1
                                            viewModel.getStoryViews()
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        LazyVStack {
                            ForEach(viewModel.likedByProfilesArray) { profile in
                                ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), showBusinessTypeDetail: false, showHeartIcon: true, onEllipsisButtonPressed: { _ in
                                    viewModel.selectedProfile = profile
                                    withAnimation(.easeInOut) {
                                        viewModel.showProfileOptions = true
                                    }
                                })
                                .onTapGesture {
                                    onPressedProfile?(profile.id)
                                }
                                .onAppear {
                                    if let lastProfile = viewModel.likedByProfilesArray.last {
                                        if lastProfile.id == profile.id {
                                            viewModel.storyLikesPageNo += 1
                                            viewModel.getStoryLikes()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 34)
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    // Profile Options
                    
                    if viewModel.showProfileOptions {
                        BottomCustomModalView4(title: viewModel.selectedProfile?.username, topButtonTitle: "block".localized(localizationManager.language), bottomButtonTitle: "remove_follower".localized(localizationManager.language), backgroundColor: .black.opacity(0.5)) {
                            // showing block modal
                            withAnimation(.easeInOut) {
                                viewModel.showProfileOptions = false
                                viewModel.showBlockModal = true
                            }
                        } onBottomButtonPressed: {
                            // showing remove follower modal
                            withAnimation(.easeInOut) {
                                viewModel.showProfileOptions = false
                                viewModel.showRemoveFollowerModal = true
                            }
                            
                        } onDismiss: {
                            withAnimation(.easeInOut) {
                                viewModel.showProfileOptions = false
                            }
                            viewModel.selectedProfile = nil
                        }
                        .transition(.move(edge: .bottom))
                    }
                    
                    // Block Modal
                    if viewModel.showBlockModal {
                        BottomCustomModalView3(
                            title: "Do you really want to block \(viewModel.selectedProfile?.username ?? "this user")?",
                            rightButtonTitle: "No",
                            leftButtonTitle: "Yes", backgroundColor: .black.opacity(0.5)) {
                                // tapped yes
                                withAnimation(.easeInOut) {
                                    viewModel.showBlockModal = false
                                }
                                viewModel.blockUser(id: viewModel.selectedProfile?.id ?? "")
                                
                            } onRightButtonPressed: {
                                // tapped no
                                withAnimation(.easeInOut) {
                                    viewModel.showBlockModal = false
                                }
                                viewModel.selectedProfile = nil
                                
                            } onDismiss: {
                                // dismiss
                                withAnimation(.easeInOut) {
                                    viewModel.showBlockModal = false
                                }
                                viewModel.selectedProfile = nil
                            }
                            .transition(.move(edge: .bottom))
                    }
                    
                    // Remove Follower Modal
                    if viewModel.showRemoveFollowerModal {
                        BottomCustomModalView3(
                            title: "Do you really want to remove \(viewModel.selectedProfile?.username ?? "this user")?",
                            rightButtonTitle: "No",
                            leftButtonTitle: "Yes", backgroundColor: .black.opacity(0.5)) {
                                // tapped yes
                                withAnimation(.easeInOut) {
                                    viewModel.showRemoveFollowerModal = false
                                }
                                viewModel.removeFollower(id: viewModel.selectedProfile?.id ?? "")
                                
                            } onRightButtonPressed: {
                                // tapped no
                                withAnimation(.easeInOut) {
                                    viewModel.showRemoveFollowerModal = false
                                }
                                viewModel.selectedProfile = nil
                                
                            } onDismiss: {
                                // dismiss
                                withAnimation(.easeInOut) {
                                    viewModel.showRemoveFollowerModal = false
                                }
                                viewModel.selectedProfile = nil
                            }
                            .transition(.move(edge: .bottom))
                    }
                    
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .overlay {
                CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
            }
        }
    }
}


// MARK: - Preview
struct StorySeenView_Previews: PreviewProvider {
    static var previews: some View {
        StorySeenView(viewModel: StorySeenViewModel(storyID: ""))
    }
}


// MARK: - Components

extension StorySeenView {
    private var customBackground: some View {
        Group {
            CustomShape2()
                .fill(themeManager.currentTheme.backgroundColor)
                .offset(y: 5)
            Image(themeManager.currentTheme.SheetIndicator)
        }
    }
    
    
    func tabButton(image: String, tabItemString: String, count: Int) -> some View {
        HStack {
            VStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .frame(width: 34, height: 34)
                    .background(
                        ZStack {
                            Circle()
                                .fill(.hmIndigo.opacity(0.3))
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.hmIndigo.opacity(0.5))
                        }
                    )
                    .overlay {
                        if viewModel.selectedTab != tabItemString {
                            Circle()
                                .fill(themeManager.currentTheme.backgroundColor.opacity(0.8))
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedTab = tabItemString
                    }
                
                if viewModel.selectedTab == tabItemString {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.hmIndigo)
                        .frame(width: 16, height: 1)
                }
            }
            
            Text("\(count)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(viewModel.selectedTab == tabItemString && themeManager.darkThemeActive ? .hmIndigo : themeManager.currentTheme.label)
            
        }
        .animation(.smooth, value: viewModel.selectedTab)
    }
    
    
    private var headerView: some View {
        HStack {
            tabButton(image: themeManager.currentTheme.eye2, tabItemString: "views", count: viewModel.totalViews)
            tabButton(image: "heartfill", tabItemString: "likes", count: viewModel.totalLikes)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
