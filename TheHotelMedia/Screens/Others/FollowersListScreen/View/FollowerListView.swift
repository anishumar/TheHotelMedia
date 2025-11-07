//
//  FollowerListView.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import SwiftUI

struct FollowerListView: View {
    
    @StateObject var viewModel: FollowerListViewModel
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            header
            
            VStack {
                HStack {
                    Text("followers".localized(localizationManager.language))
                        .foregroundColor(viewModel.currentTab == "followers" ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white06_darkGray06)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .onTapGesture {
                            viewModel.currentTab = "followers"
                        }
                    Text("following".localized(localizationManager.language))
                        .foregroundColor(viewModel.currentTab == "following" ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white06_darkGray06)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .onTapGesture {
                            viewModel.currentTab = "following"
                        }
                }
                .font(.custom(Constants.comicFont, size: 14))
                .frame(height: 32)
                
                HStack {
                    if viewModel.currentTab == "following" {
                        Spacer()
                    }
                    
                    Capsule()
                        .fill(themeManager.currentTheme.label)
                        .frame(width: UIScreen.main.bounds.width * 0.5 - 12, height: 1.5)
                        .animation(.bouncy, value: viewModel.currentTab)
                    
                    if viewModel.currentTab == "followers" {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            TabView(selection: $viewModel.currentTab,
                    content:  {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(viewModel.followersList) { profile in
                            let index = viewModel.followersList.firstIndex(where: {$0.id == profile.id })
                            ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), onEllipsisButtonPressed: { profileID in
                                if let index {
                                    viewModel.reportID = profileID
                                    viewModel.reportType = "user"
                                    viewModel.profileOptionYoffset = viewModel.followerListYOffset[index]
                                    viewModel.showProfileOptions.toggle()
                                }
                                
                            })
                            .onTapGesture {
                                viewModel.showUserProfileScreen(id: profile.id)
                            }
                            .overlay(
                                GeometryReader { geo in
                                    Color.black.opacity(0.0001)
                                        .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                        .allowsHitTesting(false)
                                }
                            )
                            .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                if let index {
                                    viewModel.followerListYOffset[index] = frame.minY
                                }
                            }
                            .onAppear {
                                if let lastProfile = viewModel.followersList.last {
                                    if lastProfile.id == profile.id {
                                        viewModel.followersPageNo += 1
                                        viewModel.getFollowers()
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay {
                    VStack {
                        if (viewModel.currentTab == "followers" && viewModel.followersList.isEmpty && !viewModel.showLoadingIndicator)
                        {
                            EmptyScreenView(image: "Person5", title: "no_user_found".localized(localizationManager.language), height: 0.7)
                        }
                    }
                    
                }
                .tag("followers")
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(viewModel.followingList) { profile in
                            let index = viewModel.followingList.firstIndex(where: {$0.id == profile.id })
                            
                            ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), onEllipsisButtonPressed: { profileID in
                                if let index {
                                    viewModel.reportID = profileID
                                    viewModel.reportType = "user"
                                    viewModel.profileOptionYoffset = viewModel.followingListYOffset[index]
                                    viewModel.showProfileOptions.toggle()
                                }
                            })
                            .onTapGesture {
                                viewModel.showUserProfileScreen(id: profile.id)
                            }
                            .overlay(
                                GeometryReader { geo in
                                    Color.black.opacity(0.0001)
                                        .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                        .allowsHitTesting(false)
                                }
                            )
                            .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                if let index {
                                    viewModel.followingListYOffset[index] = frame.minY
                                }
                            }
                            .onAppear {
                                if let lastProfile = viewModel.followingList.last {
                                    if lastProfile.id == profile.id {
                                        viewModel.followingsPageNo += 1
                                        viewModel.getFollowings()
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay {
                    VStack {
                        if (viewModel.currentTab == "following" && viewModel.followingList.isEmpty && !viewModel.showLoadingIndicator) {
                            EmptyScreenView(image: "Person5", title: "no_user_found".localized(localizationManager.language), height: 0.7)
                        }
                    }
                    
                }
                .tag("following")
            })
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .sheet(isPresented: $viewModel.showReportScreen, content: {
                ReportView(viewModel: ReportViewModel(reportID: viewModel.reportID, reportType: viewModel.reportType, onReport: { message in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                    }
                }))
                .environmentObject(themeManager)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(Constants.getReportSheetHeight())])
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showProfileOptions {
                    themeManager.currentTheme.black05_white05
                        .onTapGesture {
                            viewModel.showProfileOptions.toggle()
                        }
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showReportScreen = true
                                viewModel.showProfileOptions.toggle()
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: viewModel.profileOptionYoffset - UIApplication.topSafeAreaHeightTHM + 40)
                }
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Preview
struct FollowerListView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        FollowerListView(viewModel: FollowerListViewModel(router: router, id: "", username: "", currentTab: "followers"))
    }
}


// MARK: - Components
extension FollowerListView {
    private func capsuleButtonView(title: String) -> some View {
        Text(title)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundColor(themeManager.currentTheme.label)
            .frame(width: 74, height: 26, alignment: .center)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentTheme.darkGray05_white)
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
    }
    
    
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text(viewModel.username)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
    }
}
