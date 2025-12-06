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
    @State private var commentShowScreen = true
    
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
                                    onPressedComment: { postID in
                                        commentShowScreen = true
                                        viewModel.showCommentSection(postID: postID)
                                    },
                                    onPressedShare: { postID, _ in
                                        viewModel.showShareView(postID: postID)
                                    },
                onPressedEllpsis: { postID in
                    viewModel.handleEllipsis(postID: postID)
                },
                                    onPressedLike: { liked, count in
                                        if let postID = post.id {
                                            viewModel.likePost(postID: postID, isLiked: !liked)
                                        }
                                    },
                                    onPressedBookmark: { saved in
                                        if let postID = post.id {
                                            viewModel.bookmarkPost(postID: postID, isSaved: !saved)
                                        }
                                    },
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
                                ChatView(viewModel: chatViewModel, onLeaveChat: { _ in
                                    SocketIOViewModel.shared.leavePrivateChatEmit(user: username)
                                })
                                .environmentObject(ThemeManager.shared)
                                .navigationBarBackButtonHidden()
                                .onAppear {
                                    chatViewModel.pendingPostToShare = postData
                                    chatViewModel.sharePostViaDM(postData: postData)
                                    chatViewModel.pendingPostToShare = nil
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
            if #available(iOS 16.4, *) {
                CommentSectionView(
                    showScreen: $commentShowScreen,
                    newComment: .constant(""),
                    replyComment: .constant(nil),
                    viewModel: CommentSectionViewModel(
                        postID: viewModel.commentSectionPostID,
                        totalComments: viewModel.posts.first(where: { $0.id == viewModel.commentSectionPostID })?.comments ?? 0,
                        isEmbedded: false,
                        onAddingComment: { postID in
                            if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
                                viewModel.posts[index].comments = (viewModel.posts[index].comments ?? 0) + 1
                            }
                        },
                        onDeletingComment: { postID in
                            if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
                                viewModel.posts[index].comments = max(0, (viewModel.posts[index].comments ?? 0) - 1)
                            }
                        }
                    ),
                    isEmbedded: false,
                    onPressedProfile: { profileID in
                        viewModel.showCommentSection = false
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
                .presentationDetents([.fraction(0.7), .fraction(0.9)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            } else {
                CommentSectionView(
                    showScreen: $commentShowScreen,
                    newComment: .constant(""),
                    replyComment: .constant(nil),
                    viewModel: CommentSectionViewModel(
                        postID: viewModel.commentSectionPostID,
                        totalComments: viewModel.posts.first(where: { $0.id == viewModel.commentSectionPostID })?.comments ?? 0,
                        isEmbedded: false,
                        onAddingComment: { postID in
                            if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
                                viewModel.posts[index].comments = (viewModel.posts[index].comments ?? 0) + 1
                            }
                        },
                        onDeletingComment: { postID in
                            if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
                                viewModel.posts[index].comments = max(0, (viewModel.posts[index].comments ?? 0) - 1)
                            }
                        }
                    ),
                    isEmbedded: false,
                    onPressedProfile: { profileID in
                        viewModel.showCommentSection = false
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
                .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel.posts.isEmpty {
                viewModel.loadPosts()
            }
        }
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showPostOptionView {
                    themeManager.currentTheme.black05_white05
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.showPostOptionView = false
                        }
                    
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showPostOptionView = false
                                viewModel.showReportScreen = true
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .padding(.top, 24)
                    .padding(.trailing, 16)
                }
            }
        }
        .sheet(isPresented: $viewModel.showReportScreen, content: {
            ReportView(viewModel: ReportViewModel(reportID: viewModel.reportID, reportType: viewModel.reportType, onReport: { message in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    ErrorModalManager.showErrorModal(router: router, errorText: message)
                }
            }))
            .environmentObject(themeManager)
            .presentationDragIndicator(.hidden)
            .presentationDetents([.fraction(Constants.getReportSheetHeight())])
        })
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

