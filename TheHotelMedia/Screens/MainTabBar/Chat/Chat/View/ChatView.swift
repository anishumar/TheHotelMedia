//
//  ChatView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/11/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChatView: View {
    
//    enum Field: Hashable {
//        case input
//    }
    
    
    @StateObject var viewModel: ChatViewModel
    var onLeaveChat: ((String) -> Void)? = nil
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @AppStorage("username") var username: String = ""
    @AppStorage("lastConnectedUser") var lastConnectedUser: String = ""
    @AppStorage("ownUserID") var ownUserID: String = ""
    @AppStorage("clearChat") var clearChat: Bool = true
    @Environment(\.scenePhase) var scenePhase
    
//    @FocusState private var focusedField: Field?
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.messages, id: \.id) { content in
                        message(content: content, mediaUrl: content.mediaUrl)
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
                            .padding(.horizontal, 12)
                            .onAppear {
                                if let lastMessageID = viewModel.messages.last?.id {
                                    if lastMessageID == content.id {
                                        viewModel.pageNo += 1
                                        viewModel.getChatData()
                                    }
                                }
                            }
                    }
                    
                }
                .padding(.top, 60)
                .padding(.bottom, 50)
                .frame(minHeight: Constants.screenHeight - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM - keyboardHeightHelper.keyboardHeight, alignment: .bottom)
            }
        }
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .clipped()
        .background(
//            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            BackgroundImageView()
        )
        .overlay(alignment: .top) {
            headerView
                .sheet(isPresented: $viewModel.showReportScreen, content: {
                    ReportView(viewModel: ReportViewModel(reportID: viewModel.userID, reportType: "user", onReport: { message in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                        }
                    }))
                    .environmentObject(themeManager)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.fraction(Constants.getReportSheetHeight())])
                })
        }
        .overlay(alignment: .top, content: {
            ZStack(alignment: .topTrailing) {
                if viewModel.showOptionView {
                    themeManager.currentTheme.black08_white05
                        .onTapGesture {
                            viewModel.showOptionView.toggle()
                        }
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.showReportScreen.toggle()
                            }
                        capsuleButtonView(title: viewModel.isBlocked ? "unblock".localized(localizationManager.language).capitalized : "block".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.modalUp.toggle()
                                viewModel.showBlockModal()
                            }
                        capsuleButtonView(title: "export_chat".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.exportChat(id: viewModel.userID)
                            }
                        capsuleButtonView(title: "delete_chat".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.modalUp.toggle()
//                                viewModel.deleteChat(id: viewModel.userID)
                                viewModel.showDeleteChatModal()
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -12, y: 40)
                }
            }
        })
//        .onReceive(keyboardHeightHelper.$keyboardHeight, perform: { height in
//            if height == 0 {
//                viewModel.useEmojiKeyboard = false
//            }
//        })
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay {
            if keyboardHeightHelper.keyboardHeight > 0 {
                Rectangle()
                    .fill(.black.opacity(0.001))
                    .onTapGesture {
                        viewModel.isTextFieldFocused = false
                    }
            }
        }
        .overlay(alignment: .bottom) {
            bottomSection
        }
        .overlay(content: {
            if viewModel.modalUp {
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .ignoresSafeArea()
            }
        })
        .overlay {
            ZStack {
                if viewModel.showPdfViewer {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    Text("Loading pdf...".localized(localizationManager.language))
                        .withComicFont(18, color: themeManager.currentTheme.label)
                }
            }
        }
        .onAppear {
            viewModel.addSubscribers()
            clearChat = true
            if lastConnectedUser != username {
                viewModel.socketViewModel.configureSocket()
                print("Re-configuring socket because last connected user is not same as current user.🖐️🖐️🖐️")
            }
            
//            if viewModel.lastScreen != "recentChat" {
//                
//            }
//            viewModel.socketViewModel.insideRecentChatEmit()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                
//            }
            if viewModel.lastScreen == "recentChat" {
                viewModel.socketViewModel.leaveRecentChatEmit()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.socketViewModel.insidePrivateChat(user: viewModel.username)
                viewModel.socketViewModel.messageSeenEmit(user: viewModel.username)
            }
            
        }
        .onDisappear {
            viewModel.cancelPublishers()
            if clearChat {
                viewModel.socketViewModel.privateMessagesList.removeAll()
            }
            onLeaveChat?(viewModel.username)
            
//            viewModel.socketViewModel.leavePrivateChatEmit(user: viewModel.username)
//            if viewModel.lastScreen != "recentChat" {
//                viewModel.socketViewModel.leaveRecentChatEmit()
//            }
        }
//        .onReceive(viewModel.socketViewModel.$userConnectedOrDisconnected, perform: { isConnected in
//            if isConnected {
//                viewModel.socketViewModel.insidePrivateChat(user: viewModel.username)
//            }
//        })
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.addSubscribers()
                viewModel.socketViewModel.configureSocket {
                    viewModel.socketViewModel.fetchPrivateConversation(username: viewModel.username, pageNumber: 1)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    viewModel.socketViewModel.insidePrivateChat(user: viewModel.username)
                }
            case .inactive:
                viewModel.cancelPublishers()
                viewModel.socketViewModel.newMessage = nil
                
            case .background:
                viewModel.cancelPublishers()
                viewModel.socketViewModel.newMessage = nil
            default:
                break
            }
        }
//        .onOpenURL { url in
//            switch url.scheme {
//            case "link":
//                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//                let queryItems = components.queryItems {
//                    
//                    if let host = url.host {
//                        let urlString = url.absoluteString.replacing("link://\(host)?url=", with: "")
//                        print(urlString)
//                        if let newUrl = URL(string: urlString) {
//                            viewModel.clearData = false
//                            handleIncomingURL(newUrl)
//                        }
//                    }
//                }
//            default:
//                break
//            }
//        }
    }
}


// MARK: - Preview
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ChatView(viewModel: ChatViewModel(router: router, username: "", userID: "", profilePic: "", name: ""))
    }
}


// MARK: - Functions
extension ChatView {
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
extension ChatView {
    @ViewBuilder private func message(content: PrivateMessage, mediaUrl: String? = nil) -> some View {
        VStack(alignment: content.sentByMe == 1 ? .trailing : .leading ) {
            if let createdAt = content.createdAt,
               let showDate = content.showDate,
               showDate {
                HStack {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(themeManager.currentTheme.white04_darkGray04)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    
                    if let dateString = DateManager.checkDateForTodayOrYesterday(to: createdAt) {
                        Text(dateString)
                    } else {
                        let date = DateManager.formatDate(from: createdAt)
                        Text(date)
                    }
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(themeManager.currentTheme.white04_darkGray04)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
                .withComicFont(11, color: themeManager.currentTheme.white06_darkGray06)
            }
            
            if let sentByMe = content.sentByMe,
               let createdAt = content.createdAt {
                let isDeleted = content.isDeleted == true
                let canShowActions = sentByMe == 1 && !isDeleted && content.isUploading != true
                
                VStack(alignment: sentByMe == 1 ? .trailing : .leading, spacing: 5) {
                    
                    VStack(alignment: sentByMe == 1 ? .trailing : .leading) {
                        if isDeleted {
                            let deletedText = sentByMe == 1 ? "You deleted this message" : "This message was deleted"
                            Text(deletedText)
                                .withComicFont(13, color: themeManager.currentTheme.white06_darkGray06)
                                .italic()
                                .padding(10)
                                .background(
                                    MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                        .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05.opacity(0.65) : themeManager.currentTheme.mediumGray05_mediumGray.opacity(0.65))
                                )
                        } else if let messageContent = content.content {
                        
                        if let type = content.type {
                            if type == "text" {
                                Text(viewModel.getAttributedDescriptionWithoutTruncation(content: messageContent, id: content.id ?? ""))
                                    .textSelection(.enabled)
                                    .withComicFont(13, color: .white)
                                    .multilineTextAlignment(.leading)
                                    .padding(10)
                                    .background(
                                        MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                            .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                    )
                                    .onTapGesture {
                                        if content.isURL {
                                            if let url = URL(string: messageContent) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
//                                    .onAppear {
//                                        let isUrl = viewModel.isValidURL(messageContent)
//                                        
//                                        if isUrl {
//                                            if let index = viewModel.messages.firstIndex(where: {$0.id == content.id}) {
//                                                viewModel.messages[index].isURL = true
//                                            }
//                                        }
//                                    }
                            } else if type == "image" {
                                WebImage(url: URL(string: mediaUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: Constants.screenWidth * 0.45)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .padding(6)
                                        .background(
                                            MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                        )
                                        .overlay {
                                            if content.isUploading == true {
                                                uploadingMediaOverlay(progress: content.uploadProgress)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .padding(6)
                                            }
                                        }
                                        .onTapGesture {
                                            if content.isUploading == true { return }
                                            if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                viewModel.openSharedPostInFeed(from: content)
                                            } else if let mediaUrl {
                                                viewModel.selectedMedia = .image(urlString: mediaUrl)
                                                viewModel.showMediaPreview = true
                                            }
                                        }
                                } placeholder: {
                                    if let thumbnail = content.thumbnail {
                                        Image(uiImage: thumbnail)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: Constants.screenWidth * 0.45)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(6)
                                            .background(
                                                MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                    .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                            )
                                            .overlay {
                                                if content.isUploading == true {
                                                    uploadingMediaOverlay(progress: content.uploadProgress)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        .padding(6)
                                                }
                                            }
                                            .onTapGesture {
                                                if content.isUploading == true { return }
                                                if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                    viewModel.openSharedPostInFeed(from: content)
                                                } else {
                                                    viewModel.selectedImage = thumbnail
                                                    viewModel.showMediaPreview = true
                                                }
                                            }
                                    } else {
                                        Image("PostImagePlaceholder")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: Constants.screenWidth * 0.45)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(6)
                                            .background(
                                                MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                    .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                            )
                                            .overlay {
                                                if content.isUploading == true {
                                                    uploadingMediaOverlay(progress: content.uploadProgress)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        .padding(6)
                                                }
                                            }
                                            .onTapGesture {
                                                if content.isUploading == true { return }
                                                if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                    viewModel.openSharedPostInFeed(from: content)
                                                } else if let mediaUrl {
                                                    viewModel.selectedMedia = .image(urlString: mediaUrl)
                                                    viewModel.showMediaPreview = true
                                                }
                                            }
                                    }
                                }
                            } else if type == "video" {
                                if let thumbnail = content.thumbnail {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: Constants.screenWidth * 0.45)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .padding(6)
                                        .background(
                                            MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                        )
                                        .overlay(
                                            ZStack {
                                                if content.isUploading == true {
                                                    uploadingMediaOverlay(progress: content.uploadProgress)
                                                } else {
                                                    Button(action: {
                                                        if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                            viewModel.openSharedPostInFeed(from: content)
                                                        } else if let mediaUrl {
                                                            viewModel.selectedMedia = .video(urlString: mediaUrl)
                                                            viewModel.showMediaPreview = true
                                                        }
                                                    }, label: {
                                                        Image("PlayIcon")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 52, height: 52)
                                                    })
                                                }
                                            }
                                        )
                                } else {
                                    WebImage(url: URL(string: content.thumbnailUrl ?? "")) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: Constants.screenWidth * 0.45)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(6)
                                            .background(
                                                MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                    .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                            )
                                            .overlay(
                                                ZStack {
                                                    if content.isUploading == true {
                                                        uploadingMediaOverlay(progress: content.uploadProgress)
                                                    } else {
                                                        Button(action: {
                                                            if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                                viewModel.openSharedPostInFeed(from: content)
                                                            } else if let mediaUrl {
                                                                viewModel.selectedMedia = .video(urlString: mediaUrl)
                                                                viewModel.showMediaPreview = true
                                                            }
                                                        }, label: {
                                                            Image("PlayIcon")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 52, height: 52)
                                                        })
                                                    }
                                                }
                                            )
                                    } placeholder: {
                                        Image("PostImagePlaceholder")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: Constants.screenWidth * 0.45)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(6)
                                            .background(
                                                MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                                    .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                            )
                                            .overlay(
                                                ZStack {
                                                    if content.isUploading == true {
                                                        uploadingMediaOverlay(progress: content.uploadProgress)
                                                    } else {
                                                        Button(action: {
                                                            if (content.isSharedPost ?? false) || ((content.postID?.isEmpty) == false) {
                                                                viewModel.openSharedPostInFeed(from: content)
                                                            } else if let mediaUrl {
                                                                viewModel.selectedMedia = .video(urlString: mediaUrl)
                                                                viewModel.showMediaPreview = true
                                                            }
                                                        }, label: {
                                                            Image("PlayIcon")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 52, height: 52)
                                                        })
                                                    }
                                                }
                                            )
    //                                        .onAppear {
    //                                            Task {
    //                                                if let mediaUrl, let videoUrl = URL(string: mediaUrl) {
    //                                                    if let thumbnailImage = try? await videoUrl.generateVideoThumbnail() {
    //                                                        if let index = viewModel.messages.firstIndex(where: { $0.id == content.id ?? ""}) {
    //                                                            viewModel.messages[index].thumbnail = thumbnailImage
    //                                                        }
    //                                                    }
    //                                                }
    //                                            }
    //                                        }
                                    }
                                }
                            } else if type == "pdf" {
                                MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                    .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                    .frame(width: 120, height: 120)
                                    .overlay {
                                        VStack {
                                            Image("PDF")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 45, height: 45)
                                            
                                            Text(messageContent)
                                                .lineLimit(1)
                                                .multilineTextAlignment(.center)
                                                .withComicFont(13, color: .white.opacity(0.7))
                                                .padding(.horizontal)
                                        }
                                        .frame(width: 120)
                                    }
                                    .overlay {
                                        if content.isUploading == true {
                                            uploadingMediaOverlay(progress: content.uploadProgress)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    .onTapGesture {
                                        if content.isUploading == true { return }
                                        if let pdfData = content.pdfData {
                                            viewModel.isRemotePDFUrl = false
                                            viewModel.viewPDFName = messageContent
                                            viewModel.openPDFData = pdfData
                                            viewModel.toDownloadPDFUrl = nil
                                            viewModel.showPdfViewer.toggle()
                                        } else if let mediaUrl, let url = URL(string: mediaUrl) {
//                                            viewModel.isRemotePDFUrl = true
//                                            viewModel.viewPDFName = messageContent
//                                            viewModel.openPDFUrl = url
//                                            viewModel.showPdfViewer.toggle()
                                            viewModel.isRemotePDFUrl = false
                                            viewModel.viewPDFName = messageContent
                                            viewModel.showLoadingIndicator = true
                                            Task {
                                                do {
                                                    let pdfData = try await viewModel.pdfDownloader.downloadPDF(from: mediaUrl)
                                                    
                                                    await MainActor.run {
                                                        viewModel.showLoadingIndicator = false
                                                        viewModel.openPDFData = pdfData
                                                        viewModel.toDownloadPDFUrl = url
                                                        viewModel.showPdfViewer.toggle()
                                                    }
                                                    
                                                } catch {
                                                    await MainActor.run {
                                                        viewModel.showLoadingIndicator = false
                                                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Failed to load the PDF!")
                                                    }
                                                }
                                            }
                                        }
                                    }
                            } else if type == "story-comment" {
                                Text(sentByMe == 1 ? "You replied to story" : "Replied to your story")
                                    .withComicFont(11, color: .white.opacity(0.7))
                                
                                Rectangle()
                                    .fill(themeManager.currentTheme.backgroundColor)
                                    .frame(width: Constants.screenWidth * 0.25, height: Constants.screenWidth * 0.40)
                                    .overlay {
                                        WebImage(url: URL(string: mediaUrl ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            WebImage(url: URL(string: content.thumbnailUrl ?? ""))
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Text(messageContent)
                                    .withComicFont(13, color: .white)
                                    .multilineTextAlignment(.leading)
                                    .padding(10)
                                    .background(
                                        MessageBox(normalRadius: 12, smallRadius: 3, isMyMessage: sentByMe == 1)
                                            .fill(sentByMe == 1 ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray05_mediumGray)
                                    )
                            }
                        }
                        }
                    }
                    .frame(maxWidth: Constants.screenWidth * 0.65, alignment: sentByMe == 1 ? .trailing : .leading)
                    HStack(spacing: 4) {
                        Text(DateManager.isoDateInto24HourFormat(isoDate: createdAt))
                        if content.isEdited == true && !isDeleted {
                            Text("• edited")
                        }
                    }
                    .withComicFont(10, color: themeManager.currentTheme.label)
                }
                .contextMenu {
                    if canShowActions {
                        if content.type == "text" {
                            Button("Edit") {
                                viewModel.beginEditing(content)
                            }
                        }
                        Button(role: .destructive) {
                            viewModel.showDeleteMessageModal(content)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: content.sentByMe == 1 ? .trailing : .leading)
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

    private func uploadingMediaOverlay(progress: Double?) -> some View {
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))

            VStack(spacing: 6) {
                if let progress = progress {
                    let fraction = max(0.0, min(1.0, progress))
                    let percent = Int((fraction * 100.0).rounded())
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 3)
                            .frame(width: 26, height: 26)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(
                                Color.white.opacity(0.95),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 26, height: 26)
                    }

                    Text("\(percent)%")
                        .withComicFont(11, color: .white.opacity(0.95))
                } else {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    
                    Text("Sending...")
                        .withComicFont(11, color: .white.opacity(0.95))
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    
    private var headerView: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
//                    viewModel.socketViewModel.leavePrivateChatEmit(user: viewModel.username)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        viewModel.dismissScreen()
//                    }
                    viewModel.dismissScreen()
                }
            
            Group {
                WebImage(url: URL(string: viewModel.profilePic), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                })
                
                Text(viewModel.name)
                    .font(.custom(Constants.comicBold, size: 18))
                    .foregroundColor(themeManager.currentTheme.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onTapGesture {
                clearChat = false
                viewModel.showUserProfileScreen(id: viewModel.userID)
            }
            
            
            Spacer()
            
            Button {
                viewModel.showOptionView.toggle()
            } label: {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 32, height: 32)
                    .overlay {
                        HStack(spacing: 3) {
                            ForEach(0..<3) { _ in
                                Circle()
                                    .fill(.white)
                                    .frame(width: 3)
                            }
                        }
                    }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    
    private var bottomSection: some View {
        ZStack {
            VStack(spacing: 2) {
                if viewModel.editingMessage != nil {
                    HStack(spacing: 10) {
                        Text("Editing message")
                            .withComicFont(12, color: themeManager.currentTheme.label)
                        Spacer()
                        Text("Cancel")
                            .withComicFont(12, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .onTapGesture {
                                viewModel.cancelEditing()
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .background(themeManager.currentTheme.backgroundColor)
                }
                bottomMainPart(height: 44)
                    .padding(.horizontal, 16)
                    .background(themeManager.currentTheme.backgroundColor)
            }
//            .offset(y: -self.keyboardHeightHelper.keyboardHeight)
            .animation(.linear(duration: 0.1), value: keyboardHeightHelper.keyboardHeight)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)

    }
    
    
    private func bottomMainPart(height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            HStack {
                messageField
                    .photosPicker(
                        isPresented: $viewModel.showPhotoPicker,
                        selection: $viewModel.photoPickerItems,
                        maxSelectionCount: 1
                    )
                    .fullScreenCover(isPresented: $viewModel.showMediaPreview, onDismiss: {
                        modifyOrientation(.portrait)
                    }, content: {
                        MediaPreviewView(media: viewModel.selectedMedia, image: viewModel.selectedImage, lastScreen: "chat")
                            .background(BackgroundClearView())
                    })
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                    .background(
                        VStack {
                            if !viewModel.isTextFieldFocused {
                                Rectangle()
                                    .fill(.black.opacity(0.001))
                                    .onTapGesture {
                                        viewModel.useEmojiKeyboard = false
                                        viewModel.isTextFieldFocused = true
                                    }
                            }
                        }
                    )
                mediaButton
                    .fileImporter(isPresented: $viewModel.showFileImporter, allowedContentTypes: [.pdf]) { result in
                        viewModel.fileImporterResult = result
                    }
                    .confirmationDialog("choose_an_option".localized(localizationManager.language), isPresented: $viewModel.showOptionDialog, titleVisibility: .visible) {
                        Button("photos".localized(localizationManager.language)) {
                            viewModel.showPhotoPicker.toggle()
                        }
                        Button("fileManager".localized(localizationManager.language)) {
                            viewModel.showFileImporter = true
                        }
                        Button("cancel".localized(localizationManager.language), role: .cancel) {
                            viewModel.showOptionDialog.toggle()
                        }
                    }
                    .fullScreenCover(isPresented: $viewModel.showPdfViewer) {
                        PDFViewer(pdfURL: $viewModel.openPDFUrl, pdfData: $viewModel.openPDFData, isRemoteURL: $viewModel.isRemotePDFUrl, downloadURL: $viewModel.toDownloadPDFUrl, pdfTitle: viewModel.viewPDFName)
                            .id(viewModel.openPDFUrl)
                    }
                
                Button {
                    if viewModel.isTextFieldFocused {
                        viewModel.isTextFieldFocused = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.useEmojiKeyboard = true
                            viewModel.isTextFieldFocused = true
                        }
                    } else {
                        viewModel.useEmojiKeyboard = true
                        viewModel.isTextFieldFocused = true
                    }
                    
                } label: {
                    Image("Smile")
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 22))
                        .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .padding(.trailing, 16)
                }

            }
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
        .allowsHitTesting(true)
        
        
    }
    
    
    private var messageField: some View {
        VStack {
//            TextField(
//                "Comment Field",
//                text: $viewModel.messageFieldText,
//                prompt: Text("send_message".localized(localizationManager.language))
//                    .font(.custom(Constants.comicFont, size: 12))
//                    .foregroundColor(.white.opacity(0.7))
//                , axis: .vertical
//            )
//            .onSubmit {
//                viewModel.messageFieldText.append("\n")
//            }
            CustomTextField(
                text: $viewModel.messageFieldText,
                focus: $viewModel.isTextFieldFocused, // Pass the focus binding
                prompt: "send_message".localized(viewModel.localizationManager.language),
                promptFont: UIFont(name: Constants.comicFont, size: 13) ?? UIFont.systemFont(ofSize: 12),
                promptColor: UIColor(themeManager.currentTheme.white08_darkGray08),
                useEmojiKeyboard: viewModel.useEmojiKeyboard,
                onSubmit: {
//                    print("Submitted: \(viewModel.messageFieldText)")
//                    viewModel.messageFieldText.append("\n")
                }
            )
            .padding(.leading, 16)
            .padding(.vertical, 6)
//            .frame(width: Constants.screenWidth * 6, height: 44)
        }
//        .frame(maxHeight: 44)
        
    }
    
//    private var messageField: some View {
//        ZStack(alignment: .topLeading) {
//            if viewModel.messageFieldText.isEmpty {
//                Text("send_message".localized(localizationManager.language))
//                    .font(.custom(Constants.comicFont, size: 12))
//                    .foregroundColor(.white.opacity(0.7))
//                    .padding(.leading, 16)
//                    .padding(.vertical, 8)
//            }
//            
//            TextEditor(text: $viewModel.messageFieldText)
//                .scrollContentBackground(.hidden) // Hides the default background
//                .background(Color.clear) // Transparent background
//                .font(.custom(Constants.comicFont, size: 12))
//                .foregroundColor(.white)
//                .padding(.leading, 16)
//                .padding(.vertical, 6)
//                .frame(height: 44) // Set fixed height to enable scrolling
//                .cornerRadius(8)
//        }
//        .frame(maxWidth: .infinity)
//        .background(Color.black.opacity(0.001)) // Add background color if needed
////        .cornerRadius(8)
//    }
    
    
    private var mediaButton: some View {
        Button(action: {
            if viewModel.isTextFieldFocused {
                viewModel.isTextFieldFocused = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 ) {
                    viewModel.showOptionDialog.toggle()
                }
            } else {
                viewModel.showOptionDialog.toggle()
            }
            
        }, label: {
            Image("clip")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 22, height: 22)
        })
    }
    
    
    private func sendButton(height: CGFloat) -> some View {
        Button(action: {
            viewModel.sendOrEditCurrentText()
        }, label: {
            Image(themeManager.currentTheme.AddComment)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        })
    }
}
