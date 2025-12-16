//
//  ProfileVideoDetailView.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import SwiftUI
import SwiftfulRouting

struct ProfileVideoDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @StateObject private var viewModel: ProfileVideoDetailViewModel
    @AppStorage("isMute") var isMute: Bool = false
    
    init(userProfileID: String, initialMediaID: String?, profileData: ProfileData? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileVideoDetailViewModel(userProfileID: userProfileID, initialMediaID: initialMediaID, profileData: profileData))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if viewModel.videoPosts.isEmpty && viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("loading".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.videoPosts.isEmpty {
                VStack {
                    Spacer()
                    EmptyScreenView(image: "VideosIcon", title: "no_video_uploaded_yet".localized(localizationManager.language))
                    Spacer()
                }
            } else {
                ReelsViewRepresentable(
                    reels: convertToReels(viewModel.videos),
                    initialReelID: viewModel.targetVideoID,
                    isMuted: isMute,
                    onLoadMore: {
                        viewModel.loadVideos()
                    },
                    onVideoChanged: { index in
                        // Handle video change if needed
                    },
                    onLike: { postID, isLiked in
                        viewModel.likePost(postID: postID, isLiked: isLiked)
                    },
                    onComment: { postID in
                        viewModel.showCommentSection(postID: postID)
                    },
                    onShare: { postID in
                        viewModel.showShareView(postID: postID)
                    },
                    onBookmark: { postID, isSaved in
                        viewModel.bookmarkPost(postID: postID, isSaved: isSaved)
                    },
                    onProfileTapped: { profileID in
                        guard !profileID.isEmpty else { return }
                        viewModel.selectedProfileID = profileID
                        viewModel.showProfileScreen = true
                    }
                )
                .frame(height: UIScreen.main.bounds.height - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM - 60)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            if viewModel.videoPosts.isEmpty {
                viewModel.loadVideos()
            }
        }
        .sheet(isPresented: $viewModel.showCommentSection) {
            if #available(iOS 16.4, *) {
                CommentSectionView(
                    showScreen: .constant(true),
                    newComment: .constant(""),
                    replyComment: .constant(nil),
                    viewModel: CommentSectionViewModel(
                        postID: viewModel.commentSectionPostID,
                        totalComments: viewModel.videoPosts.first(where: { $0.id == viewModel.commentSectionPostID })?.comments ?? 0,
                        onAddingComment: { postID in
                            if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                                var post = viewModel.videoPosts[index]
                                if post.comments != nil {
                                    post.comments! += 1
                                } else {
                                    post.comments = 1
                                }
                                viewModel.videoPosts[index] = post
                            }
                        },
                        onDeletingComment: { postID in
                            if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                                var post = viewModel.videoPosts[index]
                                if post.comments != nil {
                                    post.comments! = max(0, (post.comments ?? 0) - 1)
                                }
                                viewModel.videoPosts[index] = post
                            }
                        }
                    ),
                    onPressedProfile: { userID in
                        // Handle profile navigation if needed
                    }
                )
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .presentationDetents([.fraction(0.7), .fraction(0.9)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            } else {
                CommentSectionView(
                    showScreen: .constant(true),
                    newComment: .constant(""),
                    replyComment: .constant(nil),
                    viewModel: CommentSectionViewModel(
                        postID: viewModel.commentSectionPostID,
                        totalComments: viewModel.videoPosts.first(where: { $0.id == viewModel.commentSectionPostID })?.comments ?? 0,
                        onAddingComment: { postID in
                            if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                                var post = viewModel.videoPosts[index]
                                if post.comments != nil {
                                    post.comments! += 1
                                } else {
                                    post.comments = 1
                                }
                                viewModel.videoPosts[index] = post
                            }
                        },
                        onDeletingComment: { postID in
                            if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                                var post = viewModel.videoPosts[index]
                                if post.comments != nil {
                                    post.comments! = max(0, (post.comments ?? 0) - 1)
                                }
                                viewModel.videoPosts[index] = post
                            }
                        }
                    ),
                    onPressedProfile: { userID in
                        // Handle profile navigation if needed
                    }
                )
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $viewModel.isSharePresented) {
            UnifiedShareSheet(
                shareURL: viewModel.shareURL.absoluteString,
                postData: viewModel.sharePostData,
                router: router,
                onChatSelected: { username, userID, profilePic, name in
                    viewModel.isSharePresented = false
                    if let postData = viewModel.sharePostData {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            router.showScreen(.push) { chatRouter in
                                let chatViewModel = ChatViewModel(
                                    router: chatRouter,
                                    username: username,
                                    userID: userID,
                                    profilePic: profilePic,
                                    name: name,
                                    lastScreen: "share"
                                )
                                chatViewModel.pendingPostToShare = postData
                                return ChatView(viewModel: chatViewModel, onLeaveChat: { _ in
                                    SocketIOViewModel.shared.leavePrivateChatEmit(user: username)
                                })
                                .environmentObject(ThemeManager.shared)
                                .navigationBarBackButtonHidden()
                                .onAppear {
                                    if let postToShare = chatViewModel.pendingPostToShare {
                                        chatViewModel.sharePostViaDM(postData: postToShare)
                                        chatViewModel.pendingPostToShare = nil
                                    }
                                }
                            }
                        }
                    }
                    viewModel.sharePostData = nil
                },
                onDismiss: {
                    viewModel.isSharePresented = false
                    viewModel.sharePostData = nil
                }
            )
            .environmentObject(ThemeManager.shared)
            .environmentObject(LocalizationManager.shared)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showCommentSection) {
            CommentSectionView(
                showScreen: $viewModel.showCommentSection,
                newComment: .constant(""),
                replyComment: .constant(nil),
                viewModel: CommentSectionViewModel(
                    postID: viewModel.commentSectionPostID,
                    totalComments: viewModel.videoPosts.first(where: { $0.id == viewModel.commentSectionPostID })?.comments ?? 0,
                    isEmbedded: false,
                    onAddingComment: { postID in
                        if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                            viewModel.videoPosts[index].comments = (viewModel.videoPosts[index].comments ?? 0) + 1
                        }
                    },
                    onDeletingComment: { postID in
                        if let index = viewModel.videoPosts.firstIndex(where: { $0.id == postID }) {
                            viewModel.videoPosts[index].comments = max(0, (viewModel.videoPosts[index].comments ?? 0) - 1)
                        }
                    }
                ),
                isEmbedded: false,
                onPressedProfile: { profileID in
                    // Handle profile navigation if needed
                },
                onPressedReply: { _ in },
                onReportComment: { message in
                    // Handle report if needed
                },
                onAddComment: {}
            )
            .environmentObject(ThemeManager.shared)
            .environmentObject(LocalizationManager.shared)
        }
        .fullScreenCover(isPresented: $viewModel.showProfileScreen) {
            VStack {
                RouterView { router in
                    UserProfileView2(viewModel: UserProfileViewModel(router: router, publicProfileID: viewModel.selectedProfileID))
                        .environmentObject(themeManager)
                        .environmentObject(localizationManager)
                        .navigationBarBackButtonHidden()
                        .background(BackgroundClearView())
                }
                .background(BackgroundClearView())
            }
            .background(BackgroundClearView())
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(width: 32, height: 32)
            })
            
            Text("videos".localized(localizationManager.language).capitalized)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    private func convertToReels(_ videos: [MediaRef]) -> [Reel] {
        return videos.compactMap { video in
            guard let videoID = video.id,
                  let sourceURL = video.sourceURL,
                  let url = URL(string: sourceURL) else { return nil }
            
            let thumbnailURL = video.thumbnailURL.flatMap { URL(string: $0) }
            
            // Get post data for this video
            let postData = viewModel.getPost(for: videoID)
            
            return Reel(
                id: videoID,
                url: url,
                thumbnailURL: thumbnailURL,
                views: video.views,
                postData: postData
            )
        }
    }
}

