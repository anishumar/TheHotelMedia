//
//  SavedPostView.swift
//  TheHotelMedia
//
//  Created by MAC on 15/10/24.
//

import SwiftUI

struct SavedPostView: View {
    
    @StateObject var viewModel: SavedPostViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            PostView(belongTo: .profile, posts: $viewModel.savedPostArray, viewModel: PostViewModel(router: viewModel.router), onPagination: {
                viewModel.pageNo += 1
                viewModel.getSavedPost()
            }, onPressedProfile: { profileID in
//                viewModel.showUserProfileScreen(id: profileID)
                
            }, onPressedEvent: { eventID in
//                viewModel.showEventDetailScreen(id: eventID)
                
            }, onPressedBookmark: { postID in
//                if let index = viewModel.savedPostArray.firstIndex(where:  {$0.id == postID}) {
//                    viewModel.savedPostArray.remove(at: index)
//                }
            }, onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
            .padding(.top, 50)
            .padding(.horizontal, 12)
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
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            VStack {
                if viewModel.savedPostArray.isEmpty {
                    EmptyScreenView(image: "bookmark3", title: "no_saved_post_yet".localized(localizationManager.language), height: UIScreen.main.bounds.height)
                }
            }
        }
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showPostOptionView {
                    themeManager.currentTheme.black05_white05
                        .onTapGesture {
                            viewModel.showPostOptionView.toggle()
                        }
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showReportScreen = true
                                viewModel.showPostOptionView.toggle()
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: viewModel.postOptionYOffset - UIApplication.topSafeAreaHeightTHM + 40)
                }
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(
            CustomHeaderView(title: "saved_posts".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            , alignment: .top
        )
    }
}


// MARK: - Preview
struct SavedPostView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SavedPostView(viewModel: SavedPostViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension SavedPostView {
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
}
