//
//  BlockedUsersView.swift
//  TheHotelMedia
//
//  Created by MAC on 08/11/24.
//

import SwiftUI

struct BlockedUsersView: View {
    
    @StateObject var viewModel: BlockedUsersViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(viewModel.blockedUsersArray) { profile in
                    ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), onEllipsisButtonPressed: { id in
                        viewModel.showUnblockModal(id: id)
                    })
                        .onAppear {
                            if let lastProfile = viewModel.blockedUsersArray.last {
                                if lastProfile.id == profile.id {
                                    viewModel.pageNumber += 1
                                    viewModel.getBlockedUsers()
                                }
                            }
                        }
                        .onTapGesture {
                            viewModel.showUserProfile(id: profile.id)
                        }
                }
            }
            .padding(.top, 44)
            .padding(.horizontal, 12)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            VStack {
                if viewModel.blockedUsersArray.isEmpty && !viewModel.showLoadingIndicator {
                    EmptyScreenView(image: "BlockIcon", title: "no_blocked_users".localized(localizationManager.language), height: UIScreen.main.bounds.height)
                }
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(
            CustomHeaderView(title: "blocked_users".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            , alignment: .top
        )
        .onAppear {
            viewModel.pageNumber = 1
            viewModel.totalPages = 1
            viewModel.getBlockedUsers(refreshData: true)
        }
    }
}


// MARK: - Preview
struct BlockedUsersView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        BlockedUsersView(viewModel: BlockedUsersViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}

