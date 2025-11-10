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
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach($viewModel.posts) { $post in
                            PostCardView(
                                isPaused: .constant(true),
                                postData: $post,
                                viewModel: PostCardViewModel(data: post),
                                onPressedComment: { postID in
                                    // Handle comment
                                },
                                onPressedShare: { postID, name in
                                    // Handle share
                                },
                                onPressedEllpsis: { postID in
                                    // Handle ellipsis
                                },
                                onPressedLike: { liked, count in
                                    // Update handled by binding
                                },
                                onPressedBookmark: { saved in
                                    // Update handled by binding
                                },
                                onPressedProfile: { userID in
                                    // Handle profile tap
                                }
                            )
                            .onAppear {
                                if let lastPost = viewModel.posts.last, lastPost.id == post.id {
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
}

