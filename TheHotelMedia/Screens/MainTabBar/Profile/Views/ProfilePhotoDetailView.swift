//
//  ProfilePhotoDetailView.swift
//  TheHotelMedia
//
//  Created by GPT-5 Codex on 10/11/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfilePhotoDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @StateObject private var viewModel: ProfilePhotoDetailViewModel
    @State private var hasScrolledToInitial = false
    
    init(userProfileID: String, initialMediaID: String?, profileData: ProfileData? = nil) {
        _viewModel = StateObject(wrappedValue: ProfilePhotoDetailViewModel(userProfileID: userProfileID, initialMediaID: initialMediaID, profileData: profileData))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if viewModel.posts.isEmpty && viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("loading_posts".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.posts.isEmpty {
                VStack {
                    Spacer()
                    EmptyScreenView(image: "PhotoIcon2", title: "no_photos_uploaded_yet".localized(localizationManager.language))
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.posts.indices, id: \.self) { index in
                                let post = viewModel.posts[index]
                                let postID = postIdentifier(for: post, index: index)
                                
                                PostCardView(
                                    isPaused: .constant(true),
                                    postData: $viewModel.posts[index],
                                    viewModel: PostCardViewModel(data: post),
                                    onPressedComment: { _ in },
                                    onPressedShare: { _, _ in },
                                    onPressedEllpsis: { _ in },
                                    onPressedLike: { _, _ in },
                                    onPressedBookmark: { _ in },
                                    onPressedProfile: { _ in }
                                )
                                .id(postID)
                                .onAppear {
                                    if index == viewModel.posts.indices.last {
                                        viewModel.loadPosts()
                                    }
                                }
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.shouldAutoScroll) { shouldScroll in
                        guard shouldScroll,
                              !hasScrolledToInitial,
                              let targetID = viewModel.targetPostID else { return }
                        scrollToInitialPost(proxy: proxy, targetID: targetID)
                    }
                    .onAppear {
                        if viewModel.shouldAutoScroll,
                           !hasScrolledToInitial,
                           let targetID = viewModel.targetPostID {
                            scrollToInitialPost(proxy: proxy, targetID: targetID)
                        }
                    }
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .onAppear {
            if viewModel.posts.isEmpty {
                viewModel.loadPosts()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.label)
                    .fontWeight(.bold)
                    .frame(width: 32, height: 32)
            })
            
            Text("photos".localized(localizationManager.language).capitalized)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private func postIdentifier(for post: PostData, index: Int) -> String {
        if let id = post.id, !id.isEmpty {
            return id
        }
        if let mediaID = post.mediaRef?.first?.id, !mediaID.isEmpty {
            return mediaID
        }
        return "post-\(index)"
    }
    
    private func scrollToInitialPost(proxy: ScrollViewProxy, targetID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut) {
                proxy.scrollTo(targetID, anchor: .top)
            }
            hasScrolledToInitial = true
            viewModel.shouldAutoScroll = false
        }
    }
}

