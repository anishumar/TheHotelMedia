//
//  SinglePostView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/12/24.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit
import CoreLocation

struct SinglePostView: View {
    
    @StateObject var viewModel: SinglePostViewModel
    @Binding var isPaused: Bool
    @State var isSheet = false
    @State var showing: Bool = false
    @State var offset: CGFloat = 0.0
    @State private var notificationObserver: Any?
    @State private var notificationObserver2: Any?
    @State private var readyToPlay: Bool = false
    @State private var showLocation: Bool = true
    
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    @AppStorage("isMute") var isMute: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject var keyboardHeightHelper = KeyboardHeightHelper()
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        VStack {
            if isSheet {
                VStack {
                    if showing {
                        mainContent
                            .transition(.move(edge: .trailing))
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            withAnimation(.interactiveSpring) {
                                if value.translation.width >= 0 {
                                    offset = value.translation.width
                                }
                            }
                        })
                        .onEnded { value in
                            if value.translation.width > Constants.screenWidth * 0.25 {
                                dismissScreen()
                            } else {
                                withAnimation(.interactiveSpring) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    withAnimation(.smooth(duration: 0.2)) {
                        showing = true
                    }
                }
            } else {
                mainContent
            }
        }
    }
}

// MARK: - Preview
struct SinglePostView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SinglePostView(viewModel: SinglePostViewModel(router: router, postID: "", sharedByID: ""), isPaused: .constant(false))
    }
}

// MARK: - Functions
extension SinglePostView {
    
    private func handleIncomingURL(_ url: URL) {
        // Parse the URL
        if url.host == "thehotelmedia.com" {
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
    
    
    func dismissScreen() {
        withAnimation(.smooth(duration: 0.2)) {
            showing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}


// MARK: - Main Component
extension SinglePostView {
    private var mainContent: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                header
                    .padding(.horizontal, 12)
                ScrollView(.vertical, showsIndicators: false) {
                    if viewModel.postType == "post" {
                        normalPostView
                            .padding(.horizontal, 12)
                    } else if viewModel.postType == "review" {
                        reviewPostView
                    }
                    
                    
                    CommentSectionView(showScreen: .constant(true), newComment: $viewModel.newComment, replyComment: $viewModel.replyingComment, viewModel: CommentSectionViewModel(postID: viewModel.sharedByID.isEmpty ? viewModel.sharedPostID : EncryptionHelper.decrypt(viewModel.sharedPostID) ?? "", totalComments: viewModel.data?.comments ?? 0, isEmbedded: true, onAddingComment: { postID in
                        viewModel.showLoadingIndicator = false
                        viewModel.commentFieldText = ""
                        viewModel.newComment = ""
                        viewModel.replyingComment = nil
                    }, onDeletingComment: { postID in
                        if let commentsCount = viewModel.data?.comments {
                            viewModel.data?.comments = max(0, commentsCount - 1)
                        }
                    }), isEmbedded: true, onPressedProfile: { profileID in
                        viewModel.showProfileScreen(userID: profileID)
                        
                    }, onPressedReply: { replyingComment in
                        viewModel.replyingComment = replyingComment
                    }, onReportComment: { message in
                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                    }, onAddComment: {
                        if let commentsCount = viewModel.data?.comments {
                            viewModel.data?.comments = commentsCount + 1
                        }
                    })
                        .id(viewModel.data)
                        .padding(.horizontal, 12)
                }
                
            }
            .padding(.bottom, 20)
            .frame(minWidth: Constants.screenWidth, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            )
            .onAppear {
                viewModel.addSubscribers()
    //                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    //
    //                }
                if viewModel.sharedByID.isEmpty {
                    viewModel.getPost(postID: viewModel.sharedPostID)
                } else {
                    viewModel.postShared(postID: viewModel.sharedPostID, sharedByID: viewModel.sharedByID)
                }
            }
            .onReceive(timer, perform: { _ in
                showLocation.toggle()
            })
            .overlay {
                if keyboardHeightHelper.keyboardHeight > 0 {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .onTapGesture {
                            endEditing()
                        }
                }
            }
            
            bottomSection
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onOpenURL { url in
            guard let host = url.host, host == viewModel.data?.id ?? "" else { return }
            
            switch url.scheme {
            case "feeling":
                print("Feeling tapped: \(url.host ?? "")")
            case "tags":
                print("Tags tapped")
                viewModel.showTagList.toggle()
            case "loc":
                print("Location tapped: \(url.host ?? "")")
                
                if let location = viewModel.data?.location,
                   let lat = location.lat,
                   let lng = location.lng {
                    
                    let destination = "\(lat),\(lng)"
                    if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            // Fallback to Apple Maps if Google Maps is not installed
                            if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
                                UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
                            }
                        }
                    }
                }
                
            case "readmore":
    //                guard let host = url.host, host == viewModel.data.id ?? "" else { return }
                if viewModel.data?.isExpandedDescription != nil {
                    viewModel.data!.isExpandedDescription.toggle()
                }
                if let data = viewModel.data {
                    viewModel.fullDescription = viewModel.getAttributedDescription(content: viewModel.content, data: data)
                }
                if !viewModel.avplayers.isEmpty {
                    viewModel.avplayers[viewModel.currentPage]?.play()
                }
                    
            default:
                break
            }
        }
        .sheet(isPresented: $viewModel.showTagList) {
            if #available(iOS 16.4, *) {
                TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.taggedRef), onPressedProfile: { userID in
                    viewModel.showTagList.toggle()
                    viewModel.showProfileScreen(userID: userID)
                })
                .environmentObject(themeManager)
                .presentationDetents([.fraction(0.7)])
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea()
            } else {
                TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.taggedRef), onPressedProfile: { userID in
                    viewModel.showTagList.toggle()
                    viewModel.showProfileScreen(userID: userID)
                })
                .environmentObject(themeManager)
                .presentationDetents([.fraction(0.7)])
                .ignoresSafeArea()
            }
        }
    }
}


// MARK: - CommentSection Components
extension SinglePostView {
    private var bottomSection: some View {
        ZStack {
            VStack(spacing: 2) {
                if let replyingName = viewModel.replyingName,
                   let replyProfilePic = viewModel.replyingProfilePic {
                    HStack {
                        WebImage(url: URL(string: replyProfilePic), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .padding(.leading, 16)
                                .padding(.trailing, 10)
                        }, placeholder: {
                            Image("NoProfilePic")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .padding(.leading, 16)
                                .padding(.trailing, 10)
                        })
                        
                        Text("Replying to \(replyingName)")
                            .lineLimit(1)
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "xmark")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                viewModel.replyingComment = nil
                            }
                    }
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.mediumGray_hmIndigo)
                    )
                    .padding(.horizontal, 16)
                }
                bottomMainPart(height: 44)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                    .background(themeManager.currentTheme.backgroundColor)
            }
//            .offset(y: -self.keyboardHeightHelper.keyboardHeight)
//            .animation(.linear(duration: 0.1), value: keyboardHeightHelper.keyboardHeight)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)

    }
    
    
    private func bottomMainPart(height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            commentField
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(themeManager.currentTheme.darkGray_white)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(lineWidth: 1)
                            .fill(.hmIndigo.opacity(0.7))
                    }
                )
            sendButton(height: height)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
        
        
    }
    
    
    private var commentField: some View {
        TextField(
            "Comment Field",
            text: $viewModel.commentFieldText,
            prompt: Text("add_comment".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08),
            axis: .vertical
        )
        .lineLimit(4)
        .onSubmit {
            viewModel.commentFieldText.append("\n")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        
    }
    
    
    private func sendButton(height: CGFloat) -> some View {
        Button(action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                viewModel.postComment()
                viewModel.newComment = viewModel.commentFieldText
                if !viewModel.commentFieldText.isEmpty {
                    viewModel.showLoadingIndicator = true
                }
                endEditing()
            }
        }, label: {
            Image(themeManager.currentTheme.AddComment)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        })
    }
}

// MARK: - Components
extension SinglePostView {
    
    private var normalPostView: some View {
        VStack(spacing: 12) {
            profileDetailView
//                .sheet(isPresented: $viewModel.showCommentSection, content: {
//                    if #available(iOS 16.4, *) {
//                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.commentsCount, onAddingComment: { id in
//                            
//                            viewModel.data?.comments = viewModel.commentsCount + 1
//                            
//                        }), onPressedProfile: { userID in
//                            viewModel.showCommentSection.toggle()
//                            viewModel.showProfileScreen(userID: userID)
//                            print(userID)
//                        })
//                            .presentationDetents([.fraction(0.7), .fraction(0.9)])
//                            .presentationBackground(.clear)
//                            .presentationDragIndicator(.hidden)
//                            .ignoresSafeArea()
//                    } else {
//                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.commentsCount, onAddingComment: { id in
//                            
//                            viewModel.data?.comments = viewModel.commentsCount + 1
//                            
//                        }), onPressedProfile: { userID in
//                            viewModel.showCommentSection.toggle()
//                            viewModel.showProfileScreen(userID: userID)
//                            print(userID)
//                        })
//                            .ignoresSafeArea()
//                    }
//                })
                .onTapGesture {
                    viewModel.showProfileScreen(userID: viewModel.data?.userID ?? "")
                }
            if !viewModel.mediaContent.isEmpty {
                postContentView
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
            if viewModel.mediaContent.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<viewModel.mediaContent.count) { index in
                        Circle()
                            .fill(viewModel.currentPage == index ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.lightGray_mediumGray)
                            .frame(width: 4)
                    }
                }
                .id(viewModel.mediaContent)
            }
            
            if !viewModel.content.isEmpty || !viewModel.feeling.isEmpty || !viewModel.taggedRef.isEmpty || !viewModel.location.isEmpty {
                description
            }
            divider
                .sheet(isPresented: $viewModel.isSharePresented) {
                    UnifiedShareSheet(
                        shareURL: viewModel.shareURL.absoluteString,
                        postData: viewModel.sharePostData,
                        router: viewModel.router,
                        onChatSelected: { username, userID, profilePic, name in
                            viewModel.isSharePresented = false
                            if let postData = viewModel.sharePostData {
                                // Capture postData before clearing
                                let postToShare = postData
                                // Clear immediately to prevent reuse
                                viewModel.sharePostData = nil
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.router.showScreen(.push) { chatRouter in
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
                    .presentationDragIndicator(.visible)
                }
            HStack(spacing: 6) {
                //                HMCustomButton(icon: .constant(isLiked ? "heartfill" : "heart"), count: $likeCount)
                
                HStack(spacing: 6) {
                    Image(viewModel.likedByMe ? "heartfill" : themeManager.currentTheme.heart)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .scaleEffect(viewModel.heartScale)
                    
                    Text(viewModel.likes)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundStyle(themeManager.currentTheme.label)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmIndigo.opacity(0.6))
                )
                .onTapGesture {
                    haptics(.medium)
                    viewModel.likedByMe.toggle()
                    if viewModel.likedByMe {
                        viewModel.likesCount += 1
                    } else {
                        viewModel.likesCount -= 1
                    }
                    viewModel.likePost(id: viewModel.data?.id ?? "")
                }
                
                HMCustomButton(icon: .constant(themeManager.currentTheme.comment), count: $viewModel.comments)
//                    .onTapGesture {
//                        haptics(.light)
//                        viewModel.showCommentSection = true
//                    }
                HMCustomButton(icon: .constant(themeManager.currentTheme.share), count: $viewModel.shares)
                    .onTapGesture {
                        haptics(.light)
                        viewModel.showShareView(id: viewModel.data?.id ?? "")
                    }
                
                if let views = viewModel.data?.views, views > 0 {
                    HMCustomButton(icon: .constant(themeManager.currentTheme.eye3), count: .constant(Double(views).formatNumber()))
                }
                
                Spacer()
                Button(action: {
                    haptics(.light)
                    viewModel.savedByMe.toggle()
                    viewModel.savePost(id: viewModel.data?.id ?? "")
                }) {
                    Image(viewModel.savedByMe ? "bookmarkfill" : themeManager.currentTheme.bookmark3)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
                        .animation(.none, value: viewModel.savedByMe)
                }
            }
        }
        .overlay(
            ellipsisButton
                .overlay(alignment: .topTrailing) {
                    ZStack(alignment: .topTrailing) {
                        if viewModel.showPostOptionView {
                            VStack(spacing: 6) {
                                capsuleButtonView(title: "report".localized(localizationManager.language))
                                    .onTapGesture {
                                        viewModel.reportID = viewModel.data?.id ?? ""
                                        viewModel.showReportScreen = true
                                        viewModel.showPostOptionView.toggle()
                                    }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                            )
                            .offset(x: -10, y: 36)
                        }
                    }
                }
            , alignment: .topTrailing
        )
//        .animation(.easeInOut(duration: 0.2 ), value: viewModel.currentPage)
        .onChange(of: isPaused, perform: { value in
            viewModel.isPausePost = value
        })
//        .onReceive(viewModel.$likedByMe, perform: { newValue in
//            if newValue {
//                withAnimation(.spring(duration: 0.3, bounce: 0.8, blendDuration: 1)) {
//                    viewModel.heartScale = 1.15
//                }
//            } else {
//                viewModel.heartScale = 1.0
//            }
//        })
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
                    if isSheet {
                        dismissScreen()
                    } else {
                        viewModel.dismissScreen()
                    }
                }
            
            Image(themeManager.currentTheme.Title)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 38)
        }
        .padding(.top, 12)
    }
    
    private var businessProfilePic: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 43)
            )
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                })
            )
    }
    
    
    private var individualProfilePic: some View {
        Circle()
            .fill(themeManager.currentTheme.backgroundColor)
            .frame(width: 46, height: 46)
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                })
            )
            
    }
    
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white03_darkGray03)
            .frame(height: 1)
    }
    
    
    private var description: some View {
        VStack {
            Text(viewModel.fullDescription)
        }
        .font(.custom(Constants.comicFont, size: 13.2))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
//        VStack {
//            Text(viewModel.content)
//            +
//            Text(viewModel.content.isEmpty || viewModel.feeling.isEmpty ? "" : " - ")
//            +
//            Text(viewModel.feeling)
//                .foregroundColor(.hmIndigo)
//            +
//            Text(viewModel.taggedRef.isEmpty ? "" : " - ")
//            +
//            Text(viewModel.taggedRef.isEmpty ? "" : " with ")
//            +
//            Text(viewModel.taggedRef.isEmpty ? "" : viewModel.taggedRef.count == 1 ? "\(viewModel.taggedRef[0].name ?? "")" : "\(viewModel.taggedRef[0].name ?? "") and \(viewModel.taggedRef.count - 1) others")
//                .foregroundColor(.hmIndigo)
//            +
//            Text(viewModel.taggedRef.isEmpty || viewModel.location.isEmpty ? "" : " - ")
//            +
//            Text(viewModel.location.isEmpty ? "" : " at ")
//            +
//            Text(viewModel.location)
//                .foregroundColor(.hmIndigo)
//            
//        }
//        .font(.custom(Constants.comicFont, size: 13.2))
//        .foregroundStyle(.white)
//        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var postContentView: some View {
        
        ZStack {
            WebImage(url: URL(string: viewModel.firstImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4, maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/3)
            } placeholder: {
                Image("PostImagePlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .opacity(0)
        .overlay(
            VStack {
                if !viewModel.mediaContent.isEmpty {
                    TabView(selection: $viewModel.currentPage) {
                        if !viewModel.mediaContent.isEmpty {
                            ForEach(0..<viewModel.mediaContent.count) { index in
                                if viewModel.mediaContent[index].isImage {
                                    VStack {
                                        WebImage(url: viewModel.mediaContent[index].url) { image in
                                            Rectangle()
                                                .fill(themeManager.currentTheme.backgroundColor)
                                                .overlay {
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        
                                                }
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                                .onTapGesture {
                                                    viewModel.showMediaPreview.toggle()
                                                }
                                        } placeholder: {
                                            WebImage(url: URL(string: viewModel.data?.mediaRef?[index].thumbnailURL ?? "")!)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }

                                    }
                                    .tag(index)
                                    
                                } else {
                                    Rectangle()
                                        .fill(themeManager.currentTheme.backgroundColor)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .overlay {
                                            CustomVideoPlayer(player: viewModel.avplayers[index])
                                                .onChange(of: isPaused, perform: { value in
                                                    if value {
                                                        
                                                        viewModel.avplayers[index]?.pause()
                                                        if let observer = notificationObserver {
                                                            NotificationCenter.default.removeObserver(observer)
                                                            notificationObserver = nil // Clear the observer after removal
                                                        }
                                                    } else {
                                                        
                                                        // Add observer for video end
                                                        notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: viewModel.avplayers[index]?.currentItem, queue: .main) { _ in
                                                            // Reset the video back to the start
                                                            viewModel.avplayers[index]?.seek(to: .zero)
                                                            viewModel.avplayers[index]?.play() // Optionally auto-play again
                                                        }
                                                    }
                                                })
                                                .onAppear {
                                                    viewModel.avplayers[index]?.play()
                                                    viewModel.avplayers[index]?.isMuted = isMute
                                                    // Add observer for video end
                                                }
                                                .onDisappear {
                                                    viewModel.avplayers[index]?.pause()
                                                }
                                                .tag(index)
                                                .allowsHitTesting(false)
                                        }
                                        .overlay {
                                            WebImage(url: URL(string: viewModel.data?.mediaRef?[index].thumbnailURL ?? "")!)
                                                .resizable()
                                                .scaledToFill()
                                                .opacity(isPaused ? 1.0 : 0.0)
                                            
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(alignment: .bottomTrailing, content: {
                                            ZStack {
                                                Circle()
                                                    .fill(.white.opacity(0.2))
                                                    .frame(width: 30, height: 30)
                                                Image(isMute ? "Mute" : "Unmute")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 18, height: 18)
                                                    
                                            }
                                            .offset(x: -12, y: -12)
                                            .overlay(content: {
                                                Rectangle()
                                                    .fill(.black.opacity(0.001))
                                                    .frame(width: 60, height: 60)
                                                    .onTapGesture {
                                                        isMute.toggle()
                                                    }
                                            })
                                        })
                                        .onTapGesture {
                                            viewModel.showMediaPreview.toggle()
                                        }
                                }
                                
                            }
                        }
                    }
                    .onChange(of: isMute, perform: { value in
                        viewModel.avplayers[viewModel.currentPage]?.isMuted = value
                    })
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .id(viewModel.mediaContent)
                    .fullScreenCover(isPresented: $viewModel.showMediaPreview, onDismiss: {
                        modifyOrientation(.portrait)
                    }, content: {
                        MediaPreviewView(media: viewModel.mediaContent[viewModel.currentPage])
                            .background(BackgroundClearView())
                    })
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                }
            }
        )
//        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
    }
    
    
    private var ratingView: some View {
        HStack {
            Text("\(viewModel.data?.postedBy?.businessProfileRef?.businessTypeRef?.name ?? "") - \(viewModel.data?.postedBy?.businessProfileRef?.businessSubtypeRef?.name ?? "")")
                .lineLimit(1)
            
            if let rating = viewModel.data?.postedBy?.businessProfileRef?.rating {
                if rating > 0 {
                    HStack(spacing: 2) {
                        Text("(")
                        Image("RatingStar")
                            .renderingMode(.template)
                            .foregroundColor(rating.getStarColor())
                            .frame(height: 12)
                        
                        Text("\(rating)")
                        Text(")")
                    }
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(rating.getStarColor())
                }
            }
        }
        .padding(.trailing, 40)
    }
    
    
    private var ellipsisButton: some View {
        Button(action: {
            viewModel.showPostOptionView.toggle()
        }, label: {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 28)
                .overlay(
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                )
        })
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
    
    
    private var profileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            if viewModel.accountType == "business" {
                businessProfilePic
                    .offset(y: 4)
                    .onTapGesture {
                        if let id = viewModel.data?.postedBy?.id {
                            viewModel.showProfileScreen(userID: id)
                        }
                    }
            } else {
                individualProfilePic
                    .offset(y: 4)
                    .onTapGesture {
                        if let id = viewModel.data?.postedBy?.id {
                            viewModel.showProfileScreen(userID: id)
                        }
                    }
            }
            
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(viewModel.name ?? "")
                        .font(.custom(Constants.comicFont, size: 16))
                        .lineLimit(1)
                        .foregroundStyle(themeManager.currentTheme.label)
                        .onTapGesture {
                            if let id = viewModel.data?.postedBy?.id {
                                viewModel.showProfileScreen(userID: id)
                            }
                        }
                    
                    // Display collaborators if any
                    if let collaborators = viewModel.data?.collaboratorRef, !collaborators.isEmpty {
                        Text("&")
                            .font(.custom(Constants.comicFont, size: 16))
                            .foregroundStyle(themeManager.currentTheme.label)
                        
                        ForEach(collaborators.prefix(2)) { collaborator in
                            Text(collaborator.name ?? collaborator.username ?? "")
                                .font(.custom(Constants.comicFont, size: 16))
                                .lineLimit(1)
                                .foregroundStyle(themeManager.currentTheme.label)
                                .onTapGesture {
                                    viewModel.showProfileScreen(userID: collaborator.id)
                                }
                        }
                        
                        if collaborators.count > 2 {
                            Text("+\(collaborators.count - 2)")
                                .font(.custom(Constants.comicFont, size: 16))
                                .foregroundStyle(themeManager.currentTheme.label)
                        }
                    }
                }
                .padding(.trailing, 40)
                
                if viewModel.accountType == "business" {
                    let rating = viewModel.data?.postedBy?.businessProfileRef?.rating
                    let type = viewModel.data?.postedBy?.businessProfileRef?.businessTypeRef?.name ?? ""
                    let subType = viewModel.data?.postedBy?.businessProfileRef?.businessSubtypeRef?.name ?? ""
                    
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                if viewModel.location.isEmpty {
                    Text(DateManager.getPostedAgoTime(date: viewModel.data?.createdAt ?? "", language: localizationManager.language))
                } else {
                    if showLocation {
                        Text(viewModel.location)
                    } else {
                        Text(DateManager.getPostedAgoTime(date: viewModel.data?.createdAt ?? "", language: localizationManager.language))
                    }

                }
                
            }
            .padding(.top, 2)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
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
    
    
    // Review Post Components
    
    private var reviewPostView: some View {
        VStack(spacing: 12) {
            profileDetailView
                .padding(.horizontal, 12)
//                .sheet(isPresented: $viewModel.showCommentSection, content: {
//                    if #available(iOS 16.4, *) {
//                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.commentsCount, onAddingComment: { id in
//                            
//                            viewModel.data?.comments = viewModel.commentsCount + 1
//                            
//                        }), onPressedProfile: { userID in
//                            viewModel.showCommentSection.toggle()
//                            viewModel.showProfileScreen(userID: userID)
//                            print(userID)
//                        })
//                            .presentationDetents([.fraction(0.7), .fraction(0.9)])
//                            .presentationBackground(.clear)
//                            .presentationDragIndicator(.hidden)
//                            .ignoresSafeArea()
//                    } else {
//                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: viewModel.commentSectionPostID, totalComments: viewModel.commentsCount, onAddingComment: { id in
//                            
//                            viewModel.data?.comments = viewModel.commentsCount + 1
//                            
//                        }), onPressedProfile: { userID in
//                            viewModel.showCommentSection.toggle()
//                            viewModel.showProfileScreen(userID: userID)
//                            print(userID)
//                        })
//                            .ignoresSafeArea()
//                    }
//                })
                .onTapGesture {
                    if let publicUserID = viewModel.data?.publicUserID {
                        guard publicUserID.isEmpty else {
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "this_user_is_not_registered_with_THM.".localized(localizationManager.language))
                            return
                        }
                        if let id = viewModel.data?.postedBy?.id {
                            viewModel.showProfileScreen(userID: id)
                        }
                    } else if viewModel.data?.publicUserID == nil {
                        if let id = viewModel.data?.postedBy?.id {
                            viewModel.showProfileScreen(userID: id)
                        }
                    }
                }
            reviewContentView
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
            if let content = viewModel.data?.content, !content.isEmpty {
                reviewDescription(text: content)
                    .padding(.horizontal, 12)
            }
            
            if viewModel.postType == "review" {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.data?.mediaRef ?? []) { media in
                            Rectangle()
                                .fill(themeManager.currentTheme.backgroundColor)
                                .frame(width: Constants.screenWidth * 0.25, height: Constants.screenWidth * 0.25)
                                .onTapGesture {
                                    if media.mediaType == "image" {
                                        viewModel.selectedMedia = .image(urlString: media.sourceURL ?? "")
                                        viewModel.showPreview.toggle()
                                    }
                                }
                                .overlay {
                                    WebImage(url: URL(string: media.mediaType == "video" ? media.thumbnailURL ?? "" : media.sourceURL ?? ""))
                                        .resizable()
                                        .scaledToFill()
                                        .allowsHitTesting(false)
                                }
                                .overlay(content: {
                                    if media.mediaType == "video" {
                                        Button(action: {
                                            viewModel.selectedMedia = .video(urlString: media.sourceURL ?? "")
                                            viewModel.showPreview.toggle()
                                        }, label: {
                                            Image("PlayIcon")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: Constants.screenWidth * 0.08, height: Constants.screenWidth * 0.08)
                                        })
                                    }
                                })
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .fullScreenCover(isPresented: $viewModel.showPreview, onDismiss: {
                    modifyOrientation(.portrait)
                }, content: {
                    MediaPreviewView(media: viewModel.selectedMedia)
                        .background(BackgroundClearView())
                })
                
            }
            
            divider
                .padding(.horizontal, 12)
                .sheet(isPresented: $viewModel.isSharePresented) {
                    UnifiedShareSheet(
                        shareURL: viewModel.shareURL.absoluteString,
                        postData: viewModel.sharePostData,
                        router: viewModel.router,
                        onChatSelected: { username, userID, profilePic, name in
                            viewModel.isSharePresented = false
                            if let postData = viewModel.sharePostData {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.router.showScreen(.push) { chatRouter in
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
                                            chatViewModel.sharePostViaDM(postData: postData)
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
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(viewModel.likedByMe ? "heartfill" : themeManager.currentTheme.heart)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .scaleEffect(viewModel.heartScale)
                    
                    Text(viewModel.likes)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundStyle(themeManager.currentTheme.label)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmIndigo.opacity(0.6))
                )
                
                .onTapGesture {
                    haptics(.medium)
                    viewModel.likedByMe.toggle()
                    
                    if viewModel.likedByMe {
                        viewModel.likesCount += 1
                    } else {
                        viewModel.likesCount -= 1
                    }
                    viewModel.likePost(id: viewModel.data?.id ?? "")
                }

                HMCustomButton(icon: .constant(themeManager.currentTheme.comment), count: $viewModel.comments)
//                    .onTapGesture {
//                        haptics(.light)
//                        viewModel.showCommentSection = true
//                    }
                HMCustomButton(icon: .constant(themeManager.currentTheme.share), count: $viewModel.shares)
                    .onTapGesture {
                        haptics(.light)
                        viewModel.showShareView(id: viewModel.data?.id ?? "")
                    }
                
                if let views = viewModel.data?.views, views > 0 {
                    HMCustomButton(icon: .constant(themeManager.currentTheme.eye3), count: .constant(Double(views).formatNumber()))
                }
                
                Spacer()
                Button(action: {
                    haptics(.light)
                    viewModel.savedByMe.toggle()
                    viewModel.savePost(id: viewModel.data?.id ?? "")
                }) {
                    Image(viewModel.savedByMe ? "bookmarkfill" : themeManager.currentTheme.bookmark)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
                        .animation(.none, value: viewModel.savedByMe)
                }
            }
            .padding(.horizontal, 12)
        }
        .overlay(
            ellipsisButton
                .overlay(alignment: .topTrailing) {
                    ZStack(alignment: .topTrailing) {
                        if viewModel.showPostOptionView {
                            VStack(spacing: 6) {
                                capsuleButtonView(title: "report".localized(localizationManager.language))
                                    .onTapGesture {
                                        viewModel.reportID = viewModel.data?.id ?? ""
                                        viewModel.showReportScreen = true
                                        viewModel.showPostOptionView.toggle()
                                    }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(themeManager.currentTheme.mediumGray_hmIndigo08)
                            )
                            .offset(x: -10, y: 36)
                        }
                    }
                }
            , alignment: .topTrailing
        )
        .onChange(of: isPaused, perform: { value in
            viewModel.isPausePost = value
        })
    }
    
    
    private var reviewContentView: some View {
        ZStack {
            Rectangle()
                .fill(.hmDarkerGray)
                .frame(height: 290)
                .overlay {
                    WebImage(url: viewModel.coverImage.isEmpty ? nil : URL(string: viewModel.coverImage), content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(width: Constants.screenWidth - 38)
                            .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                    }, placeholder: {
                        Image("CoverPlaceholder")
                            .resizable()
                            .scaledToFit()
                    })
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            
            
        }
        .overlay(
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
                    .frame(height: 80)
                secondProfileDetailView
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                    .onTapGesture {
                        
                        
                        if let googleReviewedBusiness = viewModel.data?.googleReviewedBusiness {
                            guard googleReviewedBusiness.isEmpty else {
                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "this_user_is_not_registered_with_THM.".localized(localizationManager.language))
                                return
                            }
                            if let userID = viewModel.data?.reviewedBusinessProfileRef?.userID {
                                viewModel.showProfileScreen(userID: userID)
                            }
                        } else if viewModel.data?.googleReviewedBusiness == nil {
                            
                            if let userID = viewModel.data?.reviewedBusinessProfileRef?.userID {
                                viewModel.showProfileScreen(userID: userID)
                            }
                        }
                    }
            }
            
            .clipShape(RoundedRectangle(cornerRadius: 14))
            , alignment: .top
        )
        .overlay(alignment: .center) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
//                    .preferredColorScheme(.dark)
                    .frame(height: 45)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                HStack {
                    HStack(spacing: 12) {
                        ForEach(0..<Int(viewModel.data?.rating ?? 0)) { index in
                            FractionalStar(fraction: 1)
                                .frame(width: 20, height: 20)
                        }
                        
                        ForEach(0..<5 - Int(viewModel.data?.rating ?? 0)) { index in
                            FractionalStar(fraction: 0)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .id(viewModel.data?.rating)
                    Spacer()
                    
                    if let rating = viewModel.data?.rating {
                        Text(rating == 1 ? "😢" : rating == 2 ? "🙁" : rating == 3 ? "😑" : rating == 4 ? "🙂" : "😍")
                            .font(.custom(Constants.comicFont, size: 20))
                    }
                    
                }
                .padding(.bottom, 12.5)
                .padding(.horizontal, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    
    private var profilePic2: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 43)
            )
            .overlay(
                WebImage(url: URL(string:  viewModel.data?.reviewedBusinessProfileRef?.profilePic?.small ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                })
            )
    }
    
    
    private func reviewDescription(text: String) -> some View {
        VStack {
            Text(text)
        }
        .font(.custom(Constants.comicFont, size: 13.2))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var secondProfileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            profilePic2
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.data?.reviewedBusinessProfileRef?.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.label)
                    .padding(.trailing, 40)
                
                let rating = viewModel.data?.reviewedBusinessProfileRef?.rating
                let type = viewModel.data?.reviewedBusinessProfileRef?.businessTypeRef?.name ?? ""
                let subType = viewModel.data?.reviewedBusinessProfileRef?.businessSubtypeRef?.name ?? ""
                
                if !type.isEmpty || !subType.isEmpty {
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                Text(viewModel.businessAddress ?? "")
                    .lineLimit(2)
            }
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
}
