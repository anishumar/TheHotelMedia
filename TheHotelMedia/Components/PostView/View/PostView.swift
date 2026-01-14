//
//  PostView.swift
//  HotelMedia
//
//  Created by MAC on 28/08/24.
//

import SwiftUI
import AVKit
import Combine
import SwiftfulRouting

struct YOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PostView: View {
    
    var belongTo: TabbedItem
    @Binding var posts: [PostData]
    @StateObject var viewModel: PostViewModel
    var showDeleteButton: Bool = false
//    var timer = Publishers.Autoconnect<Timer.TimerPublisher>(upstream: .init(interval: 0.5, runLoop: .current, mode: .common))
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
    @State var currentPost: Int? = nil
    @State var lastUpdateIndex: Int? = nil
    @State var updateTimer: Timer? = nil
    @State var viewTimer: Timer? = nil
    @State var postArray: [PostData] = []
    
    @AppStorage("isMute") var isMute: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    let idsManager = UserDefaultsManager()
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
            LazyVStack(spacing: 14) {
                ForEach(postArray, id: \.usingID) { dummyPost in
                    if let index = posts.firstIndex(where: {$0.usingID == dummyPost.usingID}) {
                        let showPost = viewModel.showPostArray[index]
                        
                        if showPost {
                            if posts[index].postType == "review" {
                                ReviewPostCard(isPaused: $viewModel.isPausedArray[index], postData: $posts[index], viewModel: ReviewPostCardViewModel(data: posts[index]), onPressedLike: {
                                    viewModel.likeAPost(id: posts[index].id ?? "")
                                    
                                } , onPressedBookmark: {
                                    viewModel.saveAPost(id: posts[index].id ?? "")
                                    onPressedBookmark?(posts[index].id ?? "")
                                    
                                }, onPressedComment: { postID in
                                    viewModel.commentSectionPostID = postID
                                    viewModel.totalComments = posts[index].comments ?? 0
                                    viewModel.showSheet = true
                                    
                                }, onPressedShare: { id in
                                    viewModel.showShareView(id: id, postData: posts[index])
                                    
                                }, onPressedProfile: { id in
                                    onPressedProfile?(id)
                                    viewModel.selectedProfileID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showProfileScreen = true
                                    
                                }, onPressedEllipsis: { postID in
                                    viewModel.visibleOptionPostIndex = index
                                    let yOffset = viewModel.yOffsetArray[viewModel.visibleOptionPostIndex] ?? 0
                                    onEllipsisPressed?(yOffset, postID)
                                }, onTapReview: { id in
                                    onTappedReview?(id)
                                    viewModel.selectedSinglePostID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showSinglePostScreen = true
//                                    viewModel.showSinglePostView(id: id)
                                }, onUserNotFound: {
                                    if let router = viewModel.router {
                                        ErrorModalManager.showErrorModal(router: router, errorText: "this_user_is_not_registered_with_THM.".localized(localizationManager.language))
                                    }
                                })
                                .environmentObject(themeManager)
                                .padding(.horizontal, belongTo == .home ? 12 : 0)
                                .frame(minWidth: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].width, minHeight: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].height)
                                .frame(maxWidth: Constants.screenWidth)
                                .overlay(
                                    GeometryReader { geo in
                                        Color.black.opacity(0.0001)
                                            .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                            .allowsHitTesting(false)
                                    }
                                )
                                .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                    updateVisibleRectangleIndex(frame: frame, index: index)
                                }
                                .onAppear {
                                    if viewModel.postCount > 5 {
                                        if index == viewModel.postCount - 5 {
                                            onPagination?()
                                        }
                                    } else {
                                        if index == viewModel.postCount - 1 {
                                            onPagination?()
                                        }
                                    }
                                    
                                }
                                
                                
                            } else if posts[index].postType == "event"{
                                
                                EventPostCard(isPaused: $viewModel.isPausedArray[index], postData: $posts[index], viewModel: EventCardViewModel(data: posts[index]), onPressedShare: { id in
                                    viewModel.showShareView(id: id, isEventPost: true, postData: posts[index])
                                }, onPressedBookmark: {
                                    viewModel.saveAPost(id: posts[index].id ?? "")
                                    onPressedBookmark?(posts[index].id ?? "")
                                }, onPressedProfile: { id in
                                    onPressedProfile?(id)
                                    viewModel.selectedProfileID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showProfileScreen = true
//                                    if belongTo == .home {
//                                        viewModel.showUserProfileScreen(id: id)
//                                    }
                                    
                                }, onPressedJoin: { id in
                                    viewModel.joinEvent(id: id)
                                }, onPressedEvent: { id in
                                    onPressedEvent?(id)
                                    viewModel.selectedEventID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showEventDetailScreen = true
                                }, onPressedEllipsis: { postID in
                                    viewModel.visibleOptionPostIndex = index
                                    let yOffset = viewModel.yOffsetArray[viewModel.visibleOptionPostIndex] ?? 0
                                    onEllipsisPressed?(yOffset, postID)
                                    
                                }, onPressedComment: { eventID in
                                    viewModel.commentSectionPostID = eventID
                                    viewModel.totalComments = posts[index].comments ?? 0
                                    viewModel.showSheet = true
                                })
                                .environmentObject(themeManager)
                                .padding(.horizontal, belongTo == .home ? 12 : 0)
                                .frame(minWidth: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].width, minHeight: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].height)
                                .frame(maxWidth: Constants.screenWidth)
                                .overlay(
                                    GeometryReader { geo in
                                        Color.black.opacity(0.0001)
                                            .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                            .allowsHitTesting(false)
                                    }
                                )
                                .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                    DispatchQueue.main.async {
                                        updateVisibleRectangleIndex(frame: frame, index: index)
                                    }
//                                    updateVisibleRectangleIndex(frame: frame, index: index)
                                }
                                .onAppear {
                                    if viewModel.postCount > 5 {
                                        if index == viewModel.postCount - 5 {
                                            onPagination?()
                                        }
                                    } else {
                                        if index == viewModel.postCount - 1 {
                                            onPagination?()
                                        }
                                    }
                                }
                                
                            } else if posts[index].postType == "post" {
                                PostCardView(isPaused: $viewModel.isPausedArray[index], postData: $posts[index], viewModel: PostCardViewModel(data: posts[index]), postIndex: index) { postID in// comment button pressed
                                    viewModel.commentSectionPostID = postID
                                    viewModel.totalComments = posts[index].comments ?? 0
                                    viewModel.showSheet = true
                                    
                                } onPressedShare: { (id, name) in// share button pressed
                                    onSharePressed?(index)
                                    viewModel.showShareView(id: id, postData: posts[index])
                                    
                                } onPressedEllpsis: { id in
                                    viewModel.visibleOptionPostIndex = index
                                    let yOffset = viewModel.yOffsetArray[viewModel.visibleOptionPostIndex] ?? 0
                                    onEllipsisPressed?(yOffset, id)
        //                            viewModel.showOptionView.toggle()
                                    
                                } onPressedLike: { liked, count in
                                    viewModel.likeAPost(id: posts[index].id ?? "")
                                    posts[index].likedByMe = liked
                                    posts[index].likes = count
                                    
                                    
                                } onPressedBookmark: { saved in// bookmark button pressed
                                    viewModel.saveAPost(id: posts[index].id ?? "")
                                    onPressedBookmark?(posts[index].id ?? "")
                                    posts[index].savedByMe = saved
                                    
                                } onPressedProfile: { id in
                                    onPressedProfile?(id)
                                    viewModel.selectedProfileID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    viewModel.isPausedArray[index] = true
                                    
                                    viewModel.showProfileScreen = true
//                                    if belongTo == .home {
//                                        viewModel.showUserProfileScreen(id: id)
//                                    }
                                } onPaused: {
                                    onPaused?()
                                    
                                } onAddingComment: { count in
                                    posts[index].comments = count
                                    viewModel.totalComments = count
                                } onPressedUrl : { url in
                                    handleIncomingURL(url)
                                } onTapMedia: { mediaIndex in
                                    viewModel.currentPostIndex = index
                                    viewModel.currentMediaIndex = mediaIndex
                                    viewModel.showMediaPreview = true
                                }
    //                            .id(posts[index])
                                .environmentObject(themeManager)
                                .padding(.horizontal, belongTo == .home ? 12 : 0)
                                .frame(minWidth: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].width, minHeight: viewModel.visiblePostIndex == index ? 0 : viewModel.postSizeArray[index].height)
                                .frame(maxWidth: Constants.screenWidth)
                                .overlay(
                                    GeometryReader { geo in
                                        Color.black.opacity(0.0001)
                                            .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                            .allowsHitTesting(false)
                                    }
                                )
                                .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                    DispatchQueue.main.async {
                                        updateVisibleRectangleIndex(frame: frame, index: index)
                                    }
//                                    updateVisibleRectangleIndex(frame: frame, index: index)
                                }
                                .onAppear {
                                    if viewModel.postCount > 5 {
                                        if index == viewModel.postCount - 5 {
                                            onPagination?()
                                        }
                                    } else {
                                        if index == viewModel.postCount - 1 {
                                            onPagination?()
                                        }
                                    }
                                }
                            } else if posts[index].postType == "suggestion" {
                                SuggestionListView(viewModel: SuggestionListViewModel(postData: posts[index]), onPressedProfile : { id in
                                    onPressedProfile?(id)
                                    viewModel.selectedProfileID = id
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showProfileScreen = true
                                    
                                }, onPressedCross: { id in
                                    onPressedSuggestionCross?(posts[index].id ?? "", id)
                                }, onViewAll: {
                                    onPressedViewAll?()
                                    
                                    if let index = viewModel.currentPostIndex {
                                        viewModel.isPausedArray[index] = true
                                    }
                                    
                                    viewModel.showAllSuggestionScreen = true
                                })
                                .environmentObject(themeManager)
                                .id(posts[index])
                                .overlay(
                                    GeometryReader { geo in
                                        Color.black.opacity(0.0001)
                                            .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                            .allowsHitTesting(false)
                                    }
                                )
                                .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                    DispatchQueue.main.async {
                                        updateVisibleRectangleIndex(frame: frame, index: index)
                                    }
//                                    updateVisibleRectangleIndex(frame: frame, index: index)
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(themeManager.currentTheme.backgroundColor)
                                .frame(width: viewModel.postSizeArray[index].width, height: viewModel.postSizeArray[index].height)
                        }
                    }
                }
            }

//        .overlay(
//            GeometryReader { geo in
//                Color.black.opacity(0.0001)
//                    .preference(key: YOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
//                    .allowsHitTesting(false)
//            }
//        )
//        .onPreferenceChange(YOffsetPreferenceKey.self) { offset in
//            viewModel.yOffsetContinuous = offset
//        }
//        .onReceive(timer, perform: { _ in
//            if viewModel.yOffset != viewModel.yOffsetContinuous {
//                onScrollChange?(true)
//            } else {
//                onScrollChange?(false)
//            }
//            
//            viewModel.yOffset = viewModel.yOffsetContinuous
//            
//        })
        .onAppear {
            viewModel.addSubscribers()
            do {
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            isMute = true
            
            let count = posts.count
            var offsetArray: [CGFloat] = []
            var isPausedArray: [Bool] = []
            
            for i in 0..<count {
                offsetArray.append(0)
                isPausedArray.append(true)
            }
            
            viewModel.yOffsetArray = offsetArray
            viewModel.isPausedArray = isPausedArray
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !viewModel.isPausedArray.isEmpty {
                    viewModel.isPausedArray[0] = false
                }
            }
            
            postArray = posts
            viewModel.postArray = posts
            viewModel.postCount = count
            
            var zeroArray: [CGSize] = []
            var boolArray: [Bool] = []
            
            for _ in 0..<count {
                zeroArray.append(.zero)
                boolArray.append(true)
            }
            
//            if count >= 3 {
//                for i in 0..<3 {
//                    boolArray[i] = true
//                }
//            } else if count == 2 {
//                boolArray[0] = true
//                boolArray[1] = true
//                
//            } else if count == 1 {
//                boolArray[0] = true
//            }
            
            viewModel.postSizeArray.append(contentsOf: zeroArray)
            viewModel.showPostArray.append(contentsOf: boolArray)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                if let index = viewModel.visiblePostIndex {
                    print("😱")
                    if viewModel.isPausedArray.count - 1 >= index {
                        viewModel.isPausedArray[index] = true
                    }
                }
            }
            
            if belongTo == .home {
                viewModel.increasePostViews(array: idsManager.retrieveArray()) {
                    idsManager.clearArray()
                }
                resetViewTimer()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showMediaPreview, onDismiss: {
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
                if let index = viewModel.currentPostIndex {
                    viewModel.isPausedArray[index] = false
                }
            })
            .background(BackgroundClearView())
        })
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .onReceive(viewModel.$visiblePostIndex, perform: { index in
            if index != nil {
                resetViewTimer()
            }
        })
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
            if let index, posts.count > viewModel.currentPostIndex ?? 0{
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
        .onDisappear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                if let index = viewModel.visiblePostIndex {
                    print("😱")
                    if viewModel.isPausedArray.count - 1 >= index {
                        viewModel.isPausedArray[index] = true
                    }
                }
            }
            viewModel.cancelSubscriptions()
            viewTimer = nil
            
            if belongTo == .home {
                print(idsManager.retrieveArray())
            }
        }
        .onChange(of: posts) { newPosts in
            viewModel.postArray = newPosts
            guard !newPosts.isEmpty else { return }
            
            let count = newPosts.count
            
            if count > 10 {
                guard count != viewModel.postCount else { return }
            }
            
            viewModel.postCount = count
            
            if viewModel.postCount <= 11 {
                viewModel.visiblePostIndex = 0
                viewModel.yOffsetArray = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                viewModel.postSizeArray = [.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero]
                viewModel.isPausedArray = [true, true, true, true, true, true, true, true, true, true, true]
                viewModel.showPostArray = [true, true, true, true, true, true, true, true, true, true, true]
//                if !viewModel.showPostArray.isEmpty {
//                    for i in 0..<10 {
//                        viewModel.showPostArray[i] = true
//                    }
//                }
                
                print("REFRESHED POSTS")
                postArray = newPosts
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !viewModel.isPausedArray.isEmpty {
                        viewModel.isPausedArray[0] = false
                    }
                }
                
            } else {
                viewModel.yOffsetArray.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
                viewModel.postSizeArray.append(contentsOf: [.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero])
                let array = [true, true, true, true, true, true, true, true, true, true, true]
                viewModel.isPausedArray.append(contentsOf: array)
                
                postArray = newPosts
                viewModel.postArray = newPosts
                viewModel.updateToShowPosts(posts: newPosts)
            }
        }
        .onReceive(AVAudioSession.sharedInstance().publisher(for: \.outputVolume), perform: { value in
            isMute = isMute
        })
        .onReceive(viewModel.$deletedPostID, perform: { value in
            DispatchQueue.main.async {
                if !value.isEmpty {
                    if let index = posts.firstIndex(where: {$0.id == value}) {
                        posts.remove(at: index)
                    }
                }
            }
        })
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
                    viewModel.showSheet.toggle()
                    onPressedProfile?(userID)
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
                    viewModel.showSheet.toggle()
                    onPressedProfile?(userID)
                    print(userID)
                })
                .environmentObject(themeManager)
                .id(viewModel.totalComments)
                .ignoresSafeArea()
            }
        })
        
        VStack {
            Rectangle()
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
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
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
                .sheet(isPresented: $viewModel.isSharePresented) {
                    if let router = viewModel.router {
                        UnifiedShareSheet(
                            shareURL: viewModel.shareURL.absoluteString,
                            postData: viewModel.sharePostData,
                            router: router,
                            onChatSelected: { username, userID, profilePic, name in
                                viewModel.isSharePresented = false
                                if let postData = viewModel.sharePostData {
                                    // Capture postData before clearing
                                    let postToShare = postData
                                    // Clear immediately to prevent reuse
                                    viewModel.sharePostData = nil
                                    
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
                                            .task {
                                                // Use task instead of onAppear to ensure it only runs once
                                                // and wait a moment for view to be fully ready
                                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                                if !chatViewModel.hasInitiatedShare {
                                                    chatViewModel.sharePostViaDM(postData: postToShare)
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            onDismiss: {
                                viewModel.isSharePresented = false
                                viewModel.sharePostData = nil
                            }
                        )
                        .environmentObject(ThemeManager.shared)
                        .environmentObject(LocalizationManager.shared)
                        .presentationDetents([.medium, .large])
                    } else {
                        // Fallback if router is not available
                        Text("Router not available")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            
            Rectangle()
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .fullScreenCover(isPresented: $viewModel.showSinglePostScreen) {
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
                .frame(height: 24)
                .fullScreenCover(isPresented: $viewModel.showEventDetailScreen) {
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
                .frame(height: 24)
                .fullScreenCover(isPresented: $viewModel.showAllSuggestionScreen) {
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
        }
        
    }
}

// MARK: - Preview
#Preview {
    PostView(belongTo: .home, posts: .constant([]), viewModel: PostViewModel())
}


// MARK: - Functions
extension PostView {
    func resetViewTimer() {
        guard belongTo == .home else { return }
        viewTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
            if let currentPost {
                if let visible = viewModel.visiblePostIndex {
                    if currentPost == visible {
                        guard posts.count > visible else { return }
                        if let id = posts[visible].id {
                            guard !idsManager.retrieveArray().contains(id) else { return }
//                            lastAddedPostID = id
                            idsManager.updateArray(with: id)
                        }
                    } else {
                        self.currentPost = visible
                    }
                }
            } else if let visible = viewModel.visiblePostIndex {
                currentPost = visible
            }
        })
    }
}



// MARK: - Functions
extension PostView {
//    private func updateVisibleRectangleIndex(frame: CGRect, index: Int) {
//        let visibleHeight = frame.intersection(UIScreen.main.bounds).height
//        
//        // Check if the rectangle is at least 90% visible
//        if visibleHeight > (frame.height * 0.7) {
//            viewModel.visiblePostIndex = index
//        }
//        
//        viewModel.yOffsetArray[index] = frame.minY
//    }
    
    private func updateVisibleRectangleIndex(frame: CGRect, index: Int) {
        let visibleHeight = frame.intersection(UIScreen.main.bounds).height

        viewModel.yOffsetArray[index] = frame.minY
        // Check if the rectangle is at least 70% visible
        if visibleHeight > (frame.height * 0.7) {
            // Avoid redundant updates
            commitVisiblePostIndexUpdate(index: index)
        }
        
        viewModel.postSizeArray[index] = CGSize(width: frame.width, height: frame.height)
    }

    private func commitVisiblePostIndexUpdate(index: Int) {
        guard viewModel.visiblePostIndex != index else { return }
        viewModel.visiblePostIndex = index
        viewModel.updateVisiblePosts(index: index)
        lastUpdateIndex = index
    }
    
    
    private func handleIncomingURL(_ url: URL) {
        // Parse the URL
        if url.host == Constants.domainName {
            let path = url.path // e.g., "/share/users"
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            
            if path.contains("/share/users") {
                if let id = queryItems?.first(where: { $0.name == "id" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
                    if let decryptedID = EncryptionHelper.decrypt(id),
                       let decryptedUserID = EncryptionHelper.decrypt(userID) {
                            
                        guard decryptedID != ownUserID else { return }
                        
                        viewModel.showSharedProfile(sharedID: decryptedID, sharedByID: decryptedUserID)
                    }
                }
            } else if path.contains("/share/posts") {
                if let postID = queryItems?.first(where: { $0.name == "postID" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
//                    if let decryptedID = EncryptionHelper.decrypt(id),
//                       let decryptedUserID = EncryptionHelper.decrypt(userID) {
//
//                        guard decryptedID != ownUserID else { return }
//
//                    }
                    viewModel.showSharePostView(postID: postID, sharedByID: userID)
                }
            } else if path.contains("/share/events") {
                if let postID = queryItems?.first(where: { $0.name == "postID" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
                    if let decryptedPostID = EncryptionHelper.decrypt(postID),
                       let decryptedUserID = EncryptionHelper.decrypt(userID) {

                        viewModel.showShareEventView(postID: decryptedPostID, sharedByID: decryptedUserID)

                    }
                    
                }
            } else if path.contains("/review") {
                if let businessProfileID = queryItems?.first(where: { $0.name == "id" })?.value,
                   let placeID = queryItems?.first(where: { $0.name == "placeID" })?.value {
                    
                    viewModel.showCreateReviewScreen(id: businessProfileID, placeID: placeID)
                }
            }
        } else {
            UIApplication.shared.open(url)
        }
    }
}


// MARK: - Components
extension PostView {
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





