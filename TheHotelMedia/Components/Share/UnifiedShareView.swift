//
//  UnifiedShareSheet.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftfulRouting
import SDWebImage

struct UnifiedShareSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.router) var envRouter
    @StateObject private var shareViewModel: ShareToChatViewModel
    
    var shareURL: String
    var postData: PostData?
    var router: AnyRouter?
    var onChatSelected: ((String, String, String, String) -> Void)?
    var onDismiss: (() -> Void)?
    var onStoryShared: (() -> Void)?
    
    @State private var searchText = ""
    @State private var isSharingAsStory = false
    @State private var showNativeShareSheet = false
    @State private var shareImage: UIImage? = nil
    
    init(shareURL: String, postData: PostData?, router: AnyRouter?, onChatSelected: ((String, String, String, String) -> Void)?, onDismiss: (() -> Void)?, onStoryShared: (() -> Void)? = nil) {
        self.shareURL = shareURL
        self.postData = postData
        self.router = router
        self.onChatSelected = onChatSelected
        self.onDismiss = onDismiss
        self.onStoryShared = onStoryShared
        
        // Router is required for UnifiedShareSheet - MediaPreviewView should use ActivityViewController
        guard let router = router else {
            fatalError("Router is required for UnifiedShareSheet. Use ActivityViewController for file sharing.")
        }
        _shareViewModel = StateObject(wrappedValue: ShareToChatViewModel(router: router))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header with close button and post preview
            topHeader
            
            // Share options and user list together
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Share action buttons
                    shareOptionsRow
                        .padding(.vertical, 15)
                    
                    Divider()
                        .background(themeManager.currentTheme.white06_darkGray06)
                        .padding(.vertical, 8)
                    
                    // User grid section
                    userGridSection
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .sheet(isPresented: $showNativeShareSheet) {
            ActivityViewController(
                activityItems: prepareActivityItems(),
                applicationActivities: nil,
                onDismiss: {
                    showNativeShareSheet = false
                    shareImage = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            shareViewModel.sharePostData = postData
            shareViewModel.loadChats()
            // Preload image for sharing if postData exists
            if postData != nil {
                loadShareImage()
            }
        }
    }
    
    @ViewBuilder
    private var topHeader: some View {
        VStack(spacing: 0) {
            // Top bar with close button
            HStack {
                Spacer()
                Button {
                    onDismiss?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.black09_white)
                            .frame(width: 30, height: 30)
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.label)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Post preview
            if let postData = postData {
                postPreviewContent(postData: postData)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.currentTheme.white06_darkGray06)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func postPreviewContent(postData: PostData) -> some View {
        HStack(spacing: 12) {
            if let firstMedia = postData.mediaRef?.first,
               let thumbnailUrl = firstMedia.thumbnailURL ?? firstMedia.sourceURL {
                WebImage(url: URL(string: thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(postData.content ?? "Post")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.label)
                    .lineLimit(2)
                
                Text("thehotelmedia.com")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.black09_white)
    }
    
    private var shareOptionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                shareOptionButton(
                    icon: "square.and.arrow.up",
                    label: "Share",
                    color: .blue
                ) {
                    showNativeShareSheet = true
                    haptics(.light)
                }
                

                
                // Share as Story button - only show if postData exists
                if postData != nil {
                    shareOptionButton(
                        icon: "plus.circle.fill",
                        label: isSharingAsStory ? "Sharing..." : "Share as Story",
                        color: .blue
                    ) {
                        sharePostAsStory()
                    }
                    .disabled(isSharingAsStory)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var userGridSection: some View {
        VStack(spacing: 16) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                    .padding(.vertical, 10)
                    .padding(.trailing, 12)
                    .onChange(of: searchText) { newValue in
                        shareViewModel.searchText = newValue
                        shareViewModel.filterChats()
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.black09_white)
            )
            .padding(.horizontal, 12)
            
            // User grid
            if !shareViewModel.filteredOnlineUsers.isEmpty || !shareViewModel.filteredRecentChats.isEmpty || !shareViewModel.filteredFollowersFollowing.isEmpty {
                LazyVStack(spacing: 8) {
                    // Online users grid
                    if !shareViewModel.filteredOnlineUsers.isEmpty {
                        Text("Online")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(shareViewModel.filteredOnlineUsers) { user in
                                userGridItem(user: user)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if !shareViewModel.filteredRecentChats.isEmpty || !shareViewModel.filteredFollowersFollowing.isEmpty {
                            Divider()
                                .background(themeManager.currentTheme.white06_darkGray06)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Recent chats grid
                    if !shareViewModel.filteredRecentChats.isEmpty {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(shareViewModel.filteredRecentChats) { chat in
                                if let username = chat.username,
                                   let userID = chat.id,
                                   let name = chat.name {
                                    chatGridItem(chat: chat, username: username, userID: userID, name: name)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if !shareViewModel.filteredFollowersFollowing.isEmpty {
                            Divider()
                                .background(themeManager.currentTheme.white06_darkGray06)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Followers and Following grid
                    if !shareViewModel.filteredFollowersFollowing.isEmpty {
                        Text("Peoples")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(shareViewModel.filteredFollowersFollowing) { profile in
                                if let username = profile.username,
                                   let name = profile.name {
                                    followerFollowingGridItem(profile: profile, username: username, userID: profile.id, name: name)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            } else if shareViewModel.gotInitialData {
                EmptyScreenView(
                    image: "EmptyInbox",
                    title: "No chats found",
                    subtitle: "Start a conversation to share posts"
                )
                .padding(.top, 40)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func shareOptionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.label)
            }
        }
    }
    
    private func userGridItem(user: ChatUser) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                WebImage(url: URL(string: user.profilePic?.small ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                
                if user.isOnline == 1 {
                    Circle()
                        .fill(.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                        )
                }
            }
            
            Text(user.name ?? "")
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            if let username = user.username,
               let userID = user.userID ?? user.id,
               let name = user.name {
                onChatSelected?(username, userID, user.profilePic?.small ?? "", name)
            }
        }
    }
    
    private func chatGridItem(chat: RecentChat, username: String, userID: String, name: String) -> some View {
        VStack(spacing: 4) {
            WebImage(url: URL(string: chat.profilePic?.small ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            onChatSelected?(username, userID, chat.profilePic?.small ?? "", name)
        }
    }
    
    private func followerFollowingGridItem(profile: SearchProfileData, username: String, userID: String, name: String) -> some View {
        VStack(spacing: 4) {
            WebImage(url: URL(string: profile.profilePic?.small ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            onChatSelected?(username, userID, profile.profilePic?.small ?? "", name)
        }
    }
    
    private func sharePostAsStory() {
        guard let postData = postData,
              let mediaRefs = postData.mediaRef,
              !mediaRefs.isEmpty,
              let firstMedia = mediaRefs.first,
              let mediaUrlString = firstMedia.sourceURL,
              let mediaURL = URL(string: mediaUrlString),
              let router = router,
              !isSharingAsStory else {
            return
        }
        
        isSharingAsStory = true
        haptics(.light)
        onDismiss?() // Close the share sheet first
        
        Task {
            // Check if it's a video or image
            let isVideo = firstMedia.mimeType?.contains("video") ?? false
            
            if isVideo {
                // For videos, download and open VideoEditorView
                await loadVideoAndOpenEditor(videoURL: mediaURL, router: router)
            } else {
                // For images, download and open EditStoryImageView
                await loadImageAndOpenEditor(imageURL: mediaURL, router: router)
            }
            
            await MainActor.run {
                isSharingAsStory = false
            }
        }
    }
    
    private func loadImageAndOpenEditor(imageURL: URL, router: AnyRouter) async {
        await withCheckedContinuation { continuation in
            SDWebImageManager.shared.loadImage(
                with: imageURL,
                options: [.highPriority],
                progress: nil
            ) { image, _, error, _, _, _ in
                Task { @MainActor in
                    if let image = image {
                        router.showScreen(.push) { router in
                            EditStoryImageView(
                                viewModel: EditStoryImageViewModel(router: router, image: image),
                                returnedImage: { editedImage, taggingData in
                                    self.postStory(image: editedImage, videoURL: nil, taggingData: taggingData, router: router)
                                },
                                onDismissed: {
                                    continuation.resume()
                                }
                            )
                            .environmentObject(ThemeManager.shared)
                            .navigationBarBackButtonHidden()
                        }
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        ErrorModalManager.showErrorModal(router: router, errorText: "Failed to load image. Please try again.")
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    private func loadVideoAndOpenEditor(videoURL: URL, router: AnyRouter) async {
        // Download video to temporary location
        do {
            let (tempURL, response) = try await URLSession.shared.download(from: videoURL)
            
            // Create a temporary file with correct extension (better for auto-cleanup)
            let fileManager = FileManager.default
            let documentsURL = fileManager.temporaryDirectory
            let uniqueID = UUID().uuidString
            // Force mp4 extension as it's the most compatible with UIVideoEditorController
            let fileName = "\(uniqueID).mp4"
            let newURL = documentsURL.appendingPathComponent(fileName)
            
            // Move the file
            if fileManager.fileExists(atPath: newURL.path) {
                try fileManager.removeItem(at: newURL)
            }
            try fileManager.moveItem(at: tempURL, to: newURL)
            
            // Check if file is valid
            let attributes = try fileManager.attributesOfItem(atPath: newURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("📦 Downloaded video size: \(fileSize) bytes at path: \(newURL.path)")
            
            if fileSize > 0 {
                await MainActor.run {
                    router.showScreen(.fullScreenCover) { router in
                        VideoEditorView(videoURL: newURL, limit: 30) { editedVideoURL in
                            guard let editedVideoURL else { return }
                            self.postStory(image: nil, videoURL: editedVideoURL, taggingData: nil, router: router)
                        }
                    }
                }
            } else {
               throw NSError(domain: "VideoDownload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Downloaded video is empty"])
            }
        } catch {
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                ErrorModalManager.showErrorModal(router: router, errorText: "Failed to load video. Please try again.")
            }
        }
    }
    
    private func postStory(image: UIImage?, videoURL: URL?, taggingData: StoryTaggingData?, router: AnyRouter) {
        let storyDataManager = StoryDataManager()
        
        // Prepare parameters
        var parameters: [String: Any] = [:]
        if let taggingData = taggingData {
            parameters["mentions"] = taggingData.mentions
            
            if let userTag = taggingData.userTagged {
                parameters["userTagged"] = userTag
                parameters["userTaggedId"] = taggingData.userTaggedId
                parameters["userTaggedPositionX"] = taggingData.userTaggedPositionX
                parameters["userTaggedPositionY"] = taggingData.userTaggedPositionY
            }
            
            if let location = taggingData.location {
                parameters["location"] = location.dictionary
                parameters["locationPositionX"] = taggingData.locationPositionX
                parameters["locationPositionY"] = taggingData.locationPositionY
            }
        }
        
        if let image = image {
            let media = MediaAttachment(id: UUID().uuidString, type: .photo(image))
            
            Task {
                do {
                    let result = try await storyDataManager.postStory(attachments: [media], parameters: parameters)
                    
                    await MainActor.run {
                        let range = 200...204
                        if result.status && range.contains(result.statusCode) {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onStoryShared?()
                            showStoryUploadedToast()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                } catch {
                    await MainActor.run {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        ErrorModalManager.showErrorModal(router: router, errorText: "Failed to share story. Please try again.")
                    }
                }
            }
        } else if let videoURL = videoURL {
            // Generate thumbnail for video
            Task {
                do {
                    let thumbnail = try await videoURL.generateVideoThumbnail()
                    let media = MediaAttachment(id: UUID().uuidString, type: .video(thumbnail ?? UIImage(), videoURL))
                    
                    let result = try await storyDataManager.postStory(attachments: [media], parameters: parameters)
                    
                    await MainActor.run {
                        let range = 200...204
                        if result.status && range.contains(result.statusCode) {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onStoryShared?()
                            showStoryUploadedToast()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                } catch {
                    await MainActor.run {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        ErrorModalManager.showErrorModal(router: router, errorText: "Failed to share story. Please try again.")
                    }
                }
            }
        }
    }
    
    @MainActor
    private func showStoryUploadedToast() {
        NotificationCenter.default.post(name: .storyUploadedFromShare, object: nil)
    }
    
    // MARK: - Native Share Sheet Support
    
    private func prepareActivityItems() -> [Any] {
        var items: [Any] = []
        
        // Add image if available (this will be used for rich previews in apps like Instagram, WhatsApp)
        if let image = shareImage {
            items.append(image)
        }
        
        // Add text description with URL if postData exists
        if let postData = postData, let content = postData.content, !content.isEmpty {
            let shareText = "\(content)\n\n\(shareURL)"
            items.append(shareText)
        } else {
            // Just add the URL if no content
            if let url = URL(string: shareURL) {
                items.append(url)
            } else {
                items.append(shareURL)
            }
        }
        
        return items
    }
    
    private func loadShareImage() {
        guard let postData = postData,
              let firstMedia = postData.mediaRef?.first,
              let mediaUrlString = firstMedia.sourceURL,
              let mediaURL = URL(string: mediaUrlString) else {
            return
        }
        
        // Only load if it's an image (not video)
        let isVideo = firstMedia.mimeType?.contains("video") ?? false
        if isVideo {
            return
        }
        
        // Load image asynchronously
        Task {
            await withCheckedContinuation { continuation in
                SDWebImageManager.shared.loadImage(
                    with: mediaURL,
                    options: [.highPriority],
                    progress: nil
                ) { image, _, _, _, _, _ in
                    Task { @MainActor in
                        self.shareImage = image
                        continuation.resume()
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let storyUploadedFromShare = Notification.Name("storyUploadedFromShare")
}

