//
//  PostView2.swift
//  TheHotelMedia
//
//  Created by MAC on 29/01/25.
//

import SwiftUI
import SwiftfulRouting
import AVKit
import UIKit

struct PostVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}


struct PostView2<Content: View>: View {
    
    var belongTo: TabbedItem
    @Binding var posts: [PostData]
    @StateObject var viewModel: PostViewModel2
    @ViewBuilder let content: Content
    var showDeleteButton: Bool = false
    var onCommentPressed: ((String) -> Void)?
    var onSharePressed: ((Int) -> Void)?
    var onPaused: (() -> Void)?
    var onPagination: (() -> Void)?
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedEvent: ((String) -> Void)? = nil
    var onPressedBookmark: ((String) -> Void)? = nil
    var onEllipsisPressed: ((CGFloat, String) -> Void)?
    var onPressedSuggestionCross: ((String, String) -> Void)?
    var onPressedViewAll: (() -> Void)?
    var onTappedReview: ((String) -> Void)?
    var onScrollChange: ((Bool) -> Void)?
    var onRefresh: (() -> Void)?
    var onNavigate: (() -> Void)?
    var onVideoTapped: ((PostData, Int) -> Void)? = nil
    @State var currentPost: Int? = nil
    //    @State var lastAddedPostID: String = ""
    @State var lastUpdateIndex: Int? = nil
    @State var updateTimer: Timer? = nil
    @State var viewTimer: Timer? = nil
    @State var scrollOffset: CGPoint = .zero
    @State var hasRefreshed: Bool = false
    @State var shareToChatViewModel: ShareToChatViewModel? = nil
    @State private var isNavigatingToChat = false
    @State private var pendingShareToChat = false
    
    //    @AppStorage("isMute") var isMute: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    let idsManager = UserDefaultsManager()
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        TrackableListView(
            isScrollingChanged: { _ in },
            onViewedPost: handleViewedPost,
            content: { listContent }
        )
        .listRowSpacing(12)
        .onReceive(viewModel.$currentPostIndex, perform: { index in
            if let index, posts.count > index {
                viewModel.currentPostId = posts[index].id ?? ""
                viewModel.currentLikedByMe = posts[index].likedByMe ?? false
                viewModel.currentSavedByMe = posts[index].savedByMe ?? false
                viewModel.currentLikesCount = posts[index].likes ?? 0
                viewModel.currentSharesCount = posts[index].shared ?? 0
                viewModel.currentCommentsCount = posts[index].comments ?? 0
            }
        })
        .onReceive(viewModel.$currentMediaIndex, perform: { index in
            if let index, posts.count > viewModel.currentPostIndex ?? 0 {
                if let postIndex = viewModel.currentPostIndex {
                    let post = posts[postIndex]
                    
                    if let mediaRef = post.mediaRef, mediaRef.count > index {
                        if mediaRef[index].mediaType == "video" {
                            viewModel.currentMedia = .video(urlString: mediaRef[index].sourceURL ?? "")
                        } else {
                            viewModel.currentMedia = .image(urlString: mediaRef[index].sourceURL ?? "")
                        }
                        viewModel.currentMediaId = mediaRef[index].id ?? ""
                    }
                }
            }
        })
//        .onChange(of: posts, perform: { newValue in
//            if newValue.count <= 11 {
//                viewModel.visiblePostIndex2.send(0)
//            }
//        })
//        .overlay(alignment: .topLeading, content: {
//            VideoOverlayView()
//                .environmentObject(viewModel)
//        })
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            viewModel.ensureArrayCapacity(for: posts.count)
            // Reset navigation flag when view appears (in case user navigated back)
            isNavigatingToChat = false
        }
        .onChange(of: posts) { _ in
            viewModel.ensureArrayCapacity(for: posts.count)
        }
        .onChange(of: posts.count) { newCount in
            viewModel.ensureArrayCapacity(for: newCount)
        }
        .onPreferenceChange(PostVisibilityPreferenceKey.self) { frames in
            updateVisiblePostIndex(frames: frames)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(alignment: .bottom, content: {
            VStack {
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .fullScreenCover(isPresented: $viewModel.showMediaPreview, onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.playVideoOnNavigateDismiss()
                        }
                        modifyOrientation(.portrait)
                        
                    }, content: {
                        MediaPreviewView(media: viewModel.currentMedia, postID: viewModel.currentPostId, mediaID: viewModel.currentMediaId, likedByMe: viewModel.currentLikedByMe, savedByMe: viewModel.currentSavedByMe, likesCount: viewModel.currentLikesCount, commentsCount: viewModel.currentCommentsCount, shareCount: viewModel.currentSharesCount, onPressedLike: { likedByMe, likesCount in
                            viewModel.likeAPost(id: viewModel.currentPostId)
                            if let index = viewModel.currentPostIndex {
                                posts[index].likedByMe = likedByMe
                                posts[index].likes = likesCount
                            }
                            
                        }, onAddingComment: {
                            if let index = viewModel.currentPostIndex {
                                if let comments = posts[index].comments {
                                    posts[index].comments = comments + 1
                                    viewModel.totalComments = comments + 1
                                }
                            }
                        }, onDismiss: {
                            if let index = viewModel.currentPostIndex, index < viewModel.isPausedArray.count {
                                viewModel.isPausedArray[index] = false
                            }
                        })
                        .background(BackgroundClearView())
                    })
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .fullScreenCover(isPresented: $viewModel.showProfileScreen, onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.playVideoOnNavigateDismiss()
                        }
                    }) {
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
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                    .sheet(isPresented: $viewModel.isSharePresented, content: {
                        shareSheetContent
                    })
                    .onChange(of: viewModel.isSharePresented) { isPresented in
                        if !isPresented {
                            // Reset navigation flag when sheet is dismissed
                            isNavigatingToChat = false
                        }
                    }
                    .onChange(of: viewModel.showShareToChat) { showChat in
                        if !showChat {
                            shareToChatViewModel = nil
                        } else {
                            if !viewModel.isSharePresented {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.isSharePresented = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        pendingShareToChat = false
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.isSharePresented) { isPresented in
                        if !isPresented {
                            if !pendingShareToChat {
                                viewModel.showShareOptions = false
                                viewModel.showShareToChat = false
                                viewModel.sharePostData = nil
                                shareToChatViewModel = nil
                            }
                        }
                    }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .fullScreenCover(isPresented: $viewModel.showSinglePostScreen, onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.playVideoOnNavigateDismiss()
                        }
                    }) {
                        VStack {
                            RouterView { router in
                                SinglePostView(viewModel: SinglePostViewModel(router: router, postID: viewModel.selectedSinglePostID), isPaused: .constant(false), isSheet: true)
                                    .background(BackgroundClearView())
                            }
                            .background(BackgroundClearView())
                        }
                        .background(BackgroundClearView())
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .fullScreenCover(isPresented: $viewModel.showEventDetailScreen, onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.playVideoOnNavigateDismiss()
                        }
                    }) {
                        VStack {
                            RouterView { router in
                                EventDetailView(viewModel: EventDetailViewModel(router: router, postID: viewModel.selectedEventID), isSheet: true)
                                    .background(BackgroundClearView())
                            }
                            .background(BackgroundClearView())
                        }
                        .background(BackgroundClearView())
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .fullScreenCover(isPresented: $viewModel.showAllSuggestionScreen, onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.playVideoOnNavigateDismiss()
                        }
                        
                    }) {
                        VStack {
                            RouterView { router in
                                SuggestionListScreen(viewModel: SuggestionScreenViewModel(router: router), isSheet: true)
                                    .background(BackgroundClearView())
                            }
                            .background(BackgroundClearView())
                        }
                        .background(BackgroundClearView())
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 19)
                    .sheet(isPresented: $viewModel.showTagList) {
                        if #available(iOS 16.4, *) {
                            TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.currentTaggedRef), onPressedProfile: { userID in
                                viewModel.showTagList.toggle()
//                                onPressedProfile?(userID)
                                onNavigate?()
                                onPressedProfile?(userID)
                                viewModel.selectedProfileID = userID
                                viewModel.pauseVideoOnNavigate()
                                viewModel.showProfileScreen = true
                            })
                            .environmentObject(themeManager)
                            .presentationDetents([.fraction(0.7)])
                            .presentationBackground(.clear)
                            .presentationDragIndicator(.hidden)
                            .ignoresSafeArea()
                        } else {
                            TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.currentTaggedRef), onPressedProfile: { userID in
                                viewModel.showTagList.toggle()
                                onNavigate?()
                                onPressedProfile?(userID)
                                viewModel.selectedProfileID = userID
                                viewModel.pauseVideoOnNavigate()
                                viewModel.showProfileScreen = true
                            })
                            .environmentObject(themeManager)
                            .presentationDetents([.fraction(0.7)])
                            .ignoresSafeArea()
                        }
                    }
                    
                
            }
            .opacity(0.001)
            .allowsHitTesting(false)
        })
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .sheet(isPresented: $viewModel.showSheet, content: {
            if #available(iOS 16.4, *) {
                CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.totalComments, onAddingComment: { id in
                    if let index = posts.firstIndex(where: {$0.id == id}) {
                        var post = posts[index]
                        if post.comments != nil {
                            post.comments! += 1
                        }
                        posts.remove(at: index)
                        posts.insert( post ,at: index)
                    }
                    
                }, onDeletingComment: { id in
                    if let index = posts.firstIndex(where: {$0.id == id}) {
                        var post = posts[index]
                        if post.comments != nil {
                            post.comments! = max(0, (post.comments ?? 0) - 1)
                        }
                        posts.remove(at: index)
                        posts.insert( post ,at: index)
                    }
                }), onPressedProfile: { userID in
                    onNavigate?()
                    viewModel.showSheet.toggle()
                    onPressedProfile?(userID)
                    viewModel.selectedProfileID = userID
                    viewModel.pauseVideoOnNavigate()
                    viewModel.showProfileScreen = true
                    print(userID)
                })
                .environmentObject(themeManager)
                .id(viewModel.totalComments)
                .presentationDetents([.fraction(0.7), .fraction(0.9)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            } else {
                CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.totalComments, onAddingComment: { id in
                    if let index = posts.firstIndex(where: {$0.id == id}) {
                        var post = posts[index]
                        if post.comments != nil {
                            post.comments! += 1
                        }
                        posts.remove(at: index)
                        posts.insert( post ,at: index)
                    }
                }, onDeletingComment: { id in
                    if let index = posts.firstIndex(where: {$0.id == id}) {
                        var post = posts[index]
                        if post.comments != nil {
                            post.comments! = max(0, (post.comments ?? 0) - 1)
                        }
                        posts.remove(at: index)
                        posts.insert( post ,at: index)
                    }
                }), onPressedProfile: { userID in
//                    viewModel.showSheet.toggle()
//                    onPressedProfile?(userID)
//                    print(userID)
                    onNavigate?()
                    viewModel.showSheet.toggle()
                    onPressedProfile?(userID)
                    viewModel.selectedProfileID = userID
                    viewModel.pauseVideoOnNavigate()
                    viewModel.showProfileScreen = true
                    print(userID)
                })
                .environmentObject(themeManager)
                .id(viewModel.totalComments)
                .ignoresSafeArea()
            }
        })
        .onChange(of: posts) { newValue in
            guard viewModel.postCount < newValue.count else { return }
            viewModel.postCount = newValue.count
            var array: [Bool] = []
            var offset: [CGFloat] = []
            var sizeArray: [CGSize] = []
            for _ in 0..<11 {
                array.append(true)
                offset.append(0)
                sizeArray.append(.zero)
            }
            viewModel.isPausedArray.append(contentsOf: array)
            viewModel.yOffsetArray.append(contentsOf: offset)
            viewModel.postSizeArray.append(contentsOf: sizeArray)
            //            viewModel.configureViewModelArray(add: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .onNavigate)) { notification in
            if let onNavigate = notification.userInfo?["onNavigate"] as? Bool {
                if onNavigate {
                    viewModel.pauseVideoOnNavigate()
                } else {
                    viewModel.playVideoOnNavigateDismiss()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setMuteStatus)) { notification in
            if let isMute = notification.userInfo?["setMuteStatus"] as? Bool {
                viewModel.isMute.send(isMute)
            }
        }
        .onAppear {
            if belongTo == .home {
                viewModel.increasePostViews(array: idsManager.retrieveArray()) {
                    idsManager.clearArray()
                }
            }
        }
    }
}
    
    
    
    extension PostView2 {
        
        @ViewBuilder
        private var shareSheetContent: some View {
            if let router = viewModel.router {
                UnifiedShareSheet(
                    shareURL: viewModel.shareURL.absoluteString,
                    postData: viewModel.sharePostData,
                    router: router,
                    onChatSelected: { username, userID, profilePic, name in
                        handleChatSelected(username: username, userID: userID, profilePic: profilePic, name: name, router: router)
                    },
                    onDismiss: {
                        viewModel.isSharePresented = false
                        viewModel.sharePostData = nil
                        isNavigatingToChat = false
                    }
                )
                .environmentObject(ThemeManager.shared)
                .environmentObject(LocalizationManager.shared)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            } else {
                Text("Router not available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        
        @ViewBuilder
        private func shareToChatContent(router: AnyRouter) -> some View {
            // Initialize ShareToChatViewModel if needed
            let viewModelToUse: ShareToChatViewModel = {
                if shareToChatViewModel == nil {
                    let newViewModel = ShareToChatViewModel(router: router)
                    newViewModel.dismissView = {
                        withAnimation {
                            viewModel.showShareToChat = false
                            viewModel.showShareOptions = true
                        }
                    }
                    DispatchQueue.main.async {
                        shareToChatViewModel = newViewModel
                    }
                    return newViewModel
                }
                return shareToChatViewModel!
            }()
            
            ShareToChatView(viewModel: viewModelToUse) { username, userID, profilePic, name in
                handleChatSelected(username: username, userID: userID, profilePic: profilePic, name: name, router: router)
            }
            .environmentObject(ThemeManager.shared)
            .environmentObject(LocalizationManager.shared)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        
        private func handleChatSelected(username: String, userID: String, profilePic: String, name: String, router: AnyRouter) {
            guard let postData = viewModel.sharePostData else { return }
            
            guard !isNavigatingToChat else {
                return
            }
            
            isNavigatingToChat = true
            
            viewModel.isSharePresented = false
            viewModel.showShareToChat = false
            viewModel.showShareOptions = false
            
            let postToShare = postData
            
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
                        // Reset navigation flag when leaving chat
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isNavigatingToChat = false
                        }
                    })
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
                    .onAppear {
                        chatViewModel.sharePostViaDM(postData: postToShare)
                    }
                    .onDisappear {
                        // Reset navigation flag when chat view disappears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isNavigatingToChat = false
                        }
                    }
                }
            }
            
            viewModel.sharePostData = nil
            shareToChatViewModel = nil
        }
        
        private func handleViewedPost() {
            if let index = viewModel.visiblePostIndex {
                guard index < posts.count, index != -1 else { return }
                if let id = posts[index].id, !id.isEmpty {
                    guard !idsManager.retrieveArray().contains(id) else { return }
                    idsManager.updateArray(with: id)
                }
            }
        }
        
        @ViewBuilder
        private var listContent: some View {
            content
                .listRowSeparator(.hidden)
                .listRowBackground(themeManager.currentTheme.backgroundColor)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: PostVisibilityPreferenceKey.self, value: [-1: geo.frame(in: .global)])
                    }
                )
                .onAppear {
                    // Ensure arrays are sized before ForEach renders
                    viewModel.ensureArrayCapacity(for: posts.count)
                }
            
            ForEach(0..<posts.count, id: \.self) { index in
                postRowView(for: index)
            }
            
            Rectangle()
                .fill(.clear)
                .frame(height: 70)
                .listRowSeparator(.hidden)
                .listRowBackground(themeManager.currentTheme.backgroundColor)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        
        private func safeIsPausedBinding(for index: Int) -> Binding<Bool> {
            return Binding(
                get: {
                    guard index >= 0, index < viewModel.isPausedArray.count else {
                        return true // Default to paused if out of bounds
                    }
                    return viewModel.isPausedArray[index]
                },
                set: { newValue in
                    guard index >= 0, index < viewModel.isPausedArray.count else {
                        // If out of bounds, ensure capacity and then set
                        viewModel.ensureArrayCapacity(for: index + 1)
                        if index < viewModel.isPausedArray.count {
                            viewModel.isPausedArray[index] = newValue
                        }
                        return
                    }
                    viewModel.isPausedArray[index] = newValue
                }
            )
        }
        
        @ViewBuilder
        private func postRowView(for index: Int) -> some View {
            let post = posts[index]
            
            GenericPostView(
                    isPaused: safeIsPausedBinding(for: index),
                    postData: $posts[index],
                    index: index,
                    viewModel: GenericPostViewModel(postData: post),
                    onCommentPressed: { id in
                        viewModel.commentSectionPostID = id
                        viewModel.totalComments = posts[index].comments ?? 0
                        viewModel.showSheet = true
                    },
                    onPressedShare: { id, name in
                        onSharePressed?(index)
                        viewModel.showShareView(id: id, postData: posts[index])
                    },
                    onPressedEllpsis: { id in
                        viewModel.visibleOptionPostIndex = index
                        let yOffset = viewModel.yOffsetArray[viewModel.visibleOptionPostIndex] ?? 0
                        onEllipsisPressed?(yOffset, id)
                    },
                    onPressedLike: {
                        viewModel.likeAPost(id: posts[index].id ?? "")
                    },
                    onPressedBookmark: {
                        viewModel.saveAPost(id: posts[index].id ?? "")
                    },
                    onPressedProfile: { id in
                        onNavigate?()
                        onPressedProfile?(id)
                        viewModel.selectedProfileID = id
                        viewModel.pauseVideoOnNavigate()
                        viewModel.showProfileScreen = true
                    },
                    onTapMedia: { mediaIndex in
                        let post = posts[index]
                        if let mediaRef = post.mediaRef,
                           mediaIndex < mediaRef.count,
                           mediaRef[mediaIndex].mediaType == "video" {
                            viewModel.pauseVideoOnNavigate()
                            viewModel.currentPostIndex = index
                            viewModel.currentMediaIndex = mediaIndex
                            onNavigate?()
                            onVideoTapped?(post, mediaIndex)
                        } else {
                            viewModel.pauseVideoOnNavigate()
                            viewModel.currentPostIndex = index
                            viewModel.currentMediaIndex = mediaIndex
                            onNavigate?()
                            viewModel.showMediaPreview = true
                        }
                    },
                    onTapReview: { id in
                        onTappedReview?(id)
                        viewModel.selectedSinglePostID = id
                        if let index = viewModel.currentPostIndex, index < viewModel.isPausedArray.count {
                            viewModel.isPausedArray[index] = true
                        }
                        viewModel.pauseVideoOnNavigate()
                        onNavigate?()
                        viewModel.showSinglePostScreen = true
                    },
                    onUserNotFound: {
                        if let router = viewModel.router {
                            ErrorModalManager.showErrorModal(router: router, errorText: "this_user_is_not_registered_with_THM.".localized(localizationManager.language))
                        }
                    },
                    onPressedJoin: { id in
                        viewModel.joinEvent(id: id)
                    },
                    onPressedEvent: { id in
                        onPressedEvent?(id)
                        viewModel.selectedEventID = id
                        viewModel.pauseVideoOnNavigate()
                        onNavigate?()
                        if let index = viewModel.currentPostIndex, index < viewModel.isPausedArray.count {
                            viewModel.isPausedArray[index] = true
                        }
                        viewModel.showEventDetailScreen = true
                    },
                    onPressedCross: { id in
                        onPressedSuggestionCross?(posts[index].id ?? "", id)
                    },
                    onViewAll: {
                        onPressedViewAll?()
                        onNavigate?()
                        if let index = viewModel.currentPostIndex, index < viewModel.isPausedArray.count {
                            viewModel.isPausedArray[index] = true
                        }
                        viewModel.showAllSuggestionScreen = true
                    },
                    onPressedTag: { ref in
                        viewModel.currentTaggedRef = ref
                        viewModel.showTagList = true
                    }
                )
                .environmentObject(viewModel)
                .id(posts[index])
                .padding(.horizontal, post.postType == "suggestion" ? 0 : 12)
                .listRowSeparator(.hidden)
                .listRowBackground(themeManager.currentTheme.backgroundColor)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onAppear {
                    // Ensure arrays have enough elements before accessing by index
                    if viewModel.isPausedArray.count <= index {
                        let additionalCount = index - viewModel.isPausedArray.count + 1
                        viewModel.isPausedArray.append(contentsOf: Array(repeating: true, count: additionalCount))
                    }
                    if viewModel.yOffsetArray.count <= index {
                        let additionalCount = index - viewModel.yOffsetArray.count + 1
                        viewModel.yOffsetArray.append(contentsOf: Array(repeating: 0 as CGFloat?, count: additionalCount))
                    }
                    if viewModel.postSizeArray.count <= index {
                        let additionalCount = index - viewModel.postSizeArray.count + 1
                        viewModel.postSizeArray.append(contentsOf: Array(repeating: .zero, count: additionalCount))
                    }
                    
                    if index >= posts.count - 3 {
                        onPagination?()
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: PostVisibilityPreferenceKey.self, value: [index: geo.frame(in: .global)])
                    }
                )
        }
        
        func randomColor() -> Color {
            return Color(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            )
        }
        
        
        private func updateVisiblePostIndex(frames: [Int: CGRect]) {
            let screenBounds = UIScreen.main.bounds
//            var gotVisibleFrame: Bool = false
            
            // Update yOffset for every post in the frames dictionary
            for (index, frame) in frames {
                if index >= 0 {
                    // Ensure yOffsetArray has enough elements
                    if viewModel.yOffsetArray.count <= index {
                        let additionalCount = index - viewModel.yOffsetArray.count + 1
                        viewModel.yOffsetArray.append(contentsOf: Array(repeating: 0 as CGFloat?, count: additionalCount))
                    }
                    viewModel.yOffsetArray[index] = frame.minY
//                    let visibleHeight = frame.intersection(screenBounds).height
//                    if visibleHeight > (frame.height * 0.7) || visibleHeight >= frame.height * 0.8, !gotVisibleFrame {
//                        // Avoid redundant updates
//                        commitVisiblePostIndexUpdate(index: index)
//                        gotVisibleFrame = true
//                    }
                } else {
                    //            scrollOffset = newOffset
                    if frame.minY >= 180, frame.minY <= 190, !hasRefreshed {
                        onRefresh?()
                        hasRefreshed = true
                    }
                    
                    if frame.minY <= 144, frame.minY >= 134, hasRefreshed {
                        hasRefreshed = false
                    }
                }
                
                //            viewModel.postSizeArray[index] = CGSize(width: frame.width, height: frame.height)
            }
            
//            // Find the most visible post
            if let mostVisible = frames.max(by: { lhs, rhs in
                let lhsVisible = lhs.value.intersection(screenBounds).height
                let rhsVisible = rhs.value.intersection(screenBounds).height
                return lhsVisible < rhsVisible
            })?.key {
                commitVisiblePostIndexUpdate(index: mostVisible)
            }
        }
        
        
        private func commitVisiblePostIndexUpdate(index: Int) {
            guard viewModel.visiblePostIndex != index || index == 0 else { return }
            viewModel.visiblePostIndex = max(index, 0)
            viewModel.visiblePostIndex2.send(max(index, 0))
        }
        
        
        
}



// MARK: - VideoView
//struct VideoOverlayView: View {
//    @EnvironmentObject var viewModel: PostViewModel2
//    
//    @State var isScrolling: Bool = false
//    @State var videoHidden: Bool = false
//    @State var currentMediaFrame: CGRect? = .zero
//    @State var currentPlayerItemID: String = ""
//    @State var visibleVideoUrl: URL? = nil
//    @State var currentPlayer: AVPlayer? = nil
//    @State var notificationObserver: Any? = nil
//    @State var refresh: Bool = false
//    @State var isHidden: Bool = true
//    
//    var playbackTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
//    var hideTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
//    
//    var body: some View {
//        VStack {
//            if !isScrolling, let frame = currentMediaFrame, !videoHidden {
//                if !currentPlayerItemID.isEmpty {
//                    if let playerItem = viewModel.avPlayerItemDic[currentPlayerItemID] {
//                        videoView(playerItem: playerItem, frame: frame)
//                        
//                    } else if let url = visibleVideoUrl {
//                        let playerItem = AVPlayerItem(url: url)
//                        videoView(playerItem: playerItem, frame: frame)
//                            .onAppear {
//                                viewModel.addPlayerItem(forKey: currentPlayerItemID, item: playerItem)
//                            }
//                    }
//                }
//            }
//        }
//        .frame(maxHeight: .infinity, alignment: .top)
//        .ignoresSafeArea()
//        .onReceive(viewModel.isScrolling) { value in
////            guard !UserDefaultsManager.shared.getNaviationStatus() else { return }
//            isScrolling = value
//        }
//        .onReceive(viewModel.videoHidden) { value in
//            videoHidden = value
//        }
//        .onReceive(viewModel.refreshVideoView) { value in
//            refresh = value
//        }
//        .onReceive(viewModel.currentMediaFrame) { value in
//            currentMediaFrame = value
//        }
//        .onReceive(viewModel.currentPlayerItemID) { value in
//            currentPlayerItemID = value
//        }
//        .onReceive(viewModel.currentPlayer) { value in
//            currentPlayer = value
//        }
//        .onReceive(viewModel.notificationObserver) { value in
//            notificationObserver = value
//        }
//        .onReceive(viewModel.visibleVideoUrl) { value in
//            visibleVideoUrl = value
//        }
//        .onReceive(playbackTimer, perform: { _ in
//            currentPlayer?.play()
//        })
//        .onReceive(viewModel.isMute, perform: { newValue in
//            currentPlayer?.isMuted = newValue
//            UserDefaultsManager.shared.setMuteStatus(newValue)
//            if !newValue {
//                do {
//                    try AVAudioSession.sharedInstance().setCategory(.playback)
//                } catch(let error) {
//                    print(error.localizedDescription)
//                }
//            } else {
//                do {
//                    try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
//                } catch(let error) {
//                    print(error.localizedDescription)
//                }
//            }
//        })
//        .onAppear {
//            viewModel.isMute.send(UserDefaultsManager.shared.getMuteStatus())
//        }
//        
//    }
//}
//
//// MARK: - Video Components
//extension VideoOverlayView {
//    private func videoView(playerItem: AVPlayerItem, frame: CGRect) -> some View {
//        CustomVideoPlayer(player: currentPlayer) {
//            currentPlayer?.play()
//        }
//        .frame(width: frame.width, height: frame.height)
//        .clipShape(RoundedRectangle(cornerRadius: 14))
//        .allowsHitTesting(false)
//        .overlay(alignment: .bottomTrailing, content: {
//            MuteButton()
//                .environmentObject(viewModel)
//                .overlay(content: {
//                    Rectangle()
//                        .fill(.black.opacity(0.001))
//                        .frame(width: 60, height: 60)
//                        .onTapGesture {
//                            let isMute = viewModel.isMute.value
//                            viewModel.isMute.send(!isMute)
//                        }
//                })
//            
//        })
//        .offset(x: frame.minX, y: frame.minY)
//        .onAppear {
//            currentPlayer?.replaceCurrentItem(with: nil)
//            //                                let playerItem = AVPlayerItem(url: URL(string: mediaRef[0].sourceURL ?? "")!)
//            if currentPlayer == nil {
//                currentPlayer = AVPlayer(playerItem: playerItem)
//            } else {
//                currentPlayer?.replaceCurrentItem(with: playerItem)
//            }
//            currentPlayer?.isMuted = viewModel.isMute.value
////            currentPlayer?.isMuted = isMute
//            currentPlayer?.automaticallyWaitsToMinimizeStalling = false
//            
//            notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: currentPlayer?.currentItem, queue: .main) { _ in
//                // Reset the video back to the start
//                currentPlayer?.seek(to: .zero)
//                currentPlayer?.play() // Optionally auto-play again
//            }
//        }
//        .onDisappear {
//            currentPlayer?.replaceCurrentItem(with: nil)
//            //            currentPlayer = nil
//            currentMediaFrame = nil
//            if let observer = notificationObserver {
//                NotificationCenter.default.removeObserver(observer)
//                notificationObserver = nil // Clear the observer after removal
//            }
//        }
//        .onTapGesture {
//            //                                    isPaused = true
//            //                                    onTapMedia?(index)
//            //                viewModel.showMediaPreview.toggle()
//        }
//    }
//}
//
//
//// MARK: - MuteButton
//
//struct MuteButton: View {
//    
//    @EnvironmentObject var viewModel: PostViewModel2
//    @State var isMute: Bool = false
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(.white.opacity(0.2))
//                .frame(width: 30, height: 30)
//                
//            Image(isMute ? "Mute" : "Unmute")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 18, height: 18)
//                
//            
//        }
//        .offset(x: -12, y: -12)
//        .onReceive(viewModel.isMute, perform: { value in
//            isMute = value
//        })
//        .onAppear {
//            isMute = viewModel.isMute.value
//        }
//        
//    }
//}

