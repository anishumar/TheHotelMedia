//
//  THMStoryDetailView2.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI
import AVKit
import AVFoundation
import SDWebImageSwiftUI

struct THMStoryDetailView2: View {
    
    @ObservedObject var viewModel: THMStoryViewModel
    @StateObject var detailViewModel: THMStoryDetailViewModel
    
    @Binding var onDrag: Bool
    @State var model: THMStoryUIModel
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var onChangeStory: Bool = false
    @State var watchingCurrentUser: Bool = false
    @State var currentStoryIndex: Int = 0
    @State var totalStories: Int = 1
    @State var currentStoryProgress: Float = 0
    @State var currentStoryDuration: Double = 15
    @StateObject private var playerManager = StoryPlayerManager()
    
    
    let userClosure: THMUserCompletionHandler?
    let onDeleteStory: ((Int) -> Void)?
    let onDismiss: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: Private Properties
    @StateObject private var keyboardManager = KeyboardManager2()
    @State private var messageFieldText: String = ""
    @State private var hideProfile: Bool = false
    @State private var longPressStarted: Bool = false
    
    private var messageViewPosition: CGFloat {
        return -keyboardManager.currentHeight
    }

    private var trimmedMessageText: String {
        messageFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSendMessage: Bool {
        !trimmedMessageText.isEmpty
    }
    
    var body: some View {
        GeometryReader { proxy in
            storyContentView(proxy: proxy)
        }
    }
    
    @ViewBuilder
    private func storyContentView(proxy: GeometryProxy) -> some View {
        let story = model.stories[currentStoryIndex]
        VStack {
            VStack {
                if story.config.mediaType == .image {
                    storyImageView(urlString: story.mediaURL)
                        .id(onChangeStory)
                } else {
                    storyVideoView(urlString: story.mediaURL)
                        .id(onChangeStory)
                }
            }
                .sheet(isPresented: $detailViewModel.showStoryLikes, onDismiss: {
                    resumePlayback()
                }, content: {
                    if #available(iOS 16.4, *) {
                        StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                            pausePlayback()
                            detailViewModel.navigatingToProfile = true
                            detailViewModel.showStoryLikes.toggle()
                            detailViewModel.showStoryUserProfile(id: userID)
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.8)])
                        .presentationBackground(.clear)
                        .presentationDragIndicator(.hidden)
                        .ignoresSafeArea()
                    } else {
                        StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                            pausePlayback()
                            detailViewModel.navigatingToProfile = true
                            detailViewModel.showStoryLikes.toggle()
                            detailViewModel.showStoryUserProfile(id: userID)
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.8)])
                        .presentationDragIndicator(.visible)
                        .ignoresSafeArea()
                    }
                })
                .overlay {
                    CustomProgressView(showIndicator: $playerManager.isLoading)
                }
                .overlay {
                    tapStoryOverlayView
                }
                .overlay(getLocationTagOverlay(story: story))
                .overlay(getUserTagOverlay(story: story))
                .overlay(alignment: .top) {
                    progressBarsAndUserView
                }
                .overlay(content: {
                    if keyboardManager.isKeyboardOpen {
                        Color.black.opacity(0.001)
                            .onTapGesture {
                                endEditing()
                            }
                    }
                })
                .overlay(alignment: .bottom) {
                    bottomSection(story: story)
                }
            .onReceive(viewModel.$currentStoryUser) { id in
                if id == model.id {
                    watchingCurrentUser = true
                    startCurrentStory()
                } else {
                    pausePlayback()
                    watchingCurrentUser = false
                }
            }
            .onReceive(timer, perform: { _ in
                updateImageProgress()
            })
            .onReceive(keyboardManager.$isKeyboardOpen) { isOpen in
                if isOpen {
                    pausePlayback()
                } else {
                    resumePlayback()
                }
            }
            .onReceive(playerManager.$progress) { progress in
                currentStoryProgress = progress
                if progress >= 100 {
                    tapNextStory()
                }
            }
            .onChange(of: currentStoryIndex) { _ in
                loadCurrentStory()
            }
            .onAppear {
                viewModel.currentStoryUser = model.id
                currentStoryIndex = 0
                totalStories = model.stories.count
                setupPlayerCallbacks()
                loadCurrentStory()
            }
            .onDisappear {
                playerManager.cleanup()
            }
            .rotation3DEffect(
                getAngle(proxy: proxy),
                axis: (x: 0, y: 1, z: 0),
                anchor: proxy.frame(in: .global).minX > 0 ? .leading : .trailing,
                perspective: 2.5
            )
            .onChange(of: onDrag) { isDragging in
                if isDragging {
                    pausePlayback()
                } else {
                    resumePlayback()
                }
            }
        }
    }
}

// MARK: - Functions
extension THMStoryDetailView2 {
    func tapNextStory() {
        pausePlayback()
        
        if currentStoryIndex < totalStories - 1 {
            currentStoryIndex += 1
        } else {
            toNextUser()
        }
    }
    
    func tapPreviousStory() {
        pausePlayback()
        
        if currentStoryIndex <= 0 {
            toPreviousUser()
        } else {
            currentStoryIndex -= 1
        }
    }
    
    
    func getAngle(proxy: GeometryProxy) -> Angle {
        let rotation: CGFloat = 45
        let progress = proxy.frame(in: .global).minX / proxy.size.width
        let degrees = rotation * progress
        return Angle(degrees: degrees)
    }
    
    func getStory() -> THMStory {
        return model.stories[currentStoryIndex]
    }
    
    func dismiss() {
        playerManager.cleanup()
        onDismiss?()
        detailViewModel.dismissScreen()
    }
    
    // MARK: - Playback Control
    private func setupPlayerCallbacks() {
        playerManager.onVideoFinished = {
            DispatchQueue.main.async {
                tapNextStory()
            }
        }
    }
    
    private func loadCurrentStory() {
        let story = model.stories[currentStoryIndex]
        currentStoryDuration = story.duration
        currentStoryProgress = 0
        
        if story.config.mediaType == .video {
            loadVideoStory(urlString: story.mediaURL)
        } else {
            playerManager.cleanup()
        }
        
        onChangeStory.toggle()
        updateStoryView()
    }
    
    private func startCurrentStory() {
        let story = model.stories[currentStoryIndex]
        if story.config.mediaType == .video {
            playerManager.play()
        }
    }
    
    private func pausePlayback() {
        playerManager.pause()
    }
    
    private func resumePlayback() {
        let story = model.stories[currentStoryIndex]
        if story.config.mediaType == .video {
            playerManager.play()
        }
    }
    
    private func resetCurrentStory() {
        playerManager.reset()
        currentStoryProgress = 0
    }
    
    private func loadVideoStory(urlString: String) {
        guard let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrl) else { return }
        
        playerManager.setupPlayer(url: url)
        
        // Get actual duration
        Task {
            let asset = AVURLAsset(url: url)
            if let duration = try? await asset.load(.duration) {
                let durationInSeconds = CMTimeGetSeconds(duration)
                await MainActor.run {
                    currentStoryDuration = max(durationInSeconds, 15.0)
                }
            }
        }
    }
    
    private func updateImageProgress() {
        let story = model.stories[currentStoryIndex]
        guard story.config.mediaType == .image else { return }
        
        let increment = 100.0 / (currentStoryDuration * 10)
        currentStoryProgress += Float(increment)
        
        if currentStoryProgress >= 100 {
            tapNextStory()
        }
    }
    
    func toNextUser() {
        if let index = viewModel.stories.firstIndex(where: {$0.id == viewModel.currentStoryUser}) {
            if index >= viewModel.stories.count - 1 {
                dismiss()
            } else {
                viewModel.currentStoryUser = viewModel.stories[index + 1].id
            }
        }
    }
    
    func toPreviousUser() {
        if let index = viewModel.stories.firstIndex(where: {$0.id == viewModel.currentStoryUser}) {
            if index > 0 {
                viewModel.currentStoryUser = viewModel.stories[index - 1].id
            } else {
                currentStoryIndex = 0
                onChangeStory.toggle()
            }
        }
    }
    
    func updateStoryView() {
        guard watchingCurrentUser else { return }
        
        let story = getStory()
        
        if !story.isViewed {
            model.stories[currentStoryIndex].isViewed = true
            if !model.isMyStory {
                detailViewModel.viewStory(id: story.id)
            }
        }
    }
    
    func handleStoryDeletion() {
        // Remove the deleted story from the model
        let deletedIndex = currentStoryIndex
        model.stories.remove(at: deletedIndex)
        totalStories = model.stories.count
        
        // Also update the viewModel's stories array
        if let index = viewModel.stories.firstIndex(where: { $0.id == model.id }) {
            viewModel.stories[index].stories = model.stories
        }
        
        // Reset player
        playerManager.cleanup()
        
        // Navigate to next story or user
        if model.stories.isEmpty {
            // No more stories for this user, remove from viewModel and go to next user
            if let index = viewModel.stories.firstIndex(where: { $0.id == model.id }) {
                viewModel.stories.remove(at: index)
            }
            
            // Navigate to next user or dismiss if no more users
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if viewModel.stories.isEmpty {
                    // No more stories at all, dismiss
                    dismiss()
                } else {
                    // Go to next user
                    toNextUser()
                }
            }
        } else {
            // There are more stories for this user
            if currentStoryIndex >= model.stories.count {
                // We were at the last story, go to the new last one
                currentStoryIndex = model.stories.count - 1
            }
            // Reset progress and update view
            currentStoryProgress = 0
            onChangeStory.toggle()
            loadCurrentStory()
            
            // Notify parent if needed
            onDeleteStory?(deletedIndex)
        }
    }
}


// MARK: - Components
extension THMStoryDetailView2 {
    private func storyImageView(urlString: String) -> some View {
        ZStack {
            // Black background for aspect fit
            Rectangle()
                .fill(Color.black)
            
            WebImage(url: URL(string: urlString)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .onAppear {
                        updateStoryView()
                    }
            } placeholder: {
                Rectangle()
                    .fill(.black)
            }
        }
    }
    
    
    private func storyVideoView(urlString: String) -> some View {
        CustomVideoPlayer(
            player: playerManager.avPlayer,
            contentMode: .resizeAspect,
            backgroundColor: UIColor(themeManager.currentTheme.backgroundColor)
        ) {
            playerManager.play()
        } onTimeControlStatusChange: { _ in
            // Status handled by playerManager
        }
        .onReceive(detailViewModel.$pauseVideo) { shouldPause in
            if shouldPause {
                playerManager.pause()
            } else {
                playerManager.play()
            }
        }
    }
    
    
    private func overlapingProfileImagesView(viewsRef: [StoryLikeRef]) -> some View {
        HStack(spacing: -10) {
            ForEach(viewsRef) { likeRef in
                WebImage(url: URL(string: likeRef.accountType == "individual" ? likeRef.profilePic?.small ?? "" : likeRef.businessProfileRef?.profilePic?.small ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                })
                
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                Capsule()
                    .fill(.hmIndigo.opacity(0.3))
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.5))
            }
        )
    }
    
    
    private var tapStoryOverlayView: some View {
        HStack {
            Rectangle()
                .fill(.black.opacity(0.001))
                .onLongPressGesture(minimumDuration: 0.3, perform: {
                    
                }, onPressingChanged: { isPressing in
                    if isPressing {
                        pausePlayback()
                        hideProfile = true
                    } else {
                        resumePlayback()
                        hideProfile = false
                    }
                })
                .onTapGesture {
                    tapPreviousStory()
                }
            Rectangle()
                .fill(.black.opacity(0.001))
                .onLongPressGesture(minimumDuration: 0.3, perform: {
                    
                }, onPressingChanged: { isPressing in
                    if isPressing {
                        pausePlayback()
                        hideProfile = true
                    } else {
                        resumePlayback()
                        hideProfile = false
                    }
                })
                .onTapGesture {
                    tapNextStory()
                }
        }
    }
    
    
    private var progressBarsAndUserView: some View {
        let date = model.stories[currentStoryIndex].date
        let name = model.user.name
        let image = model.user.image
        return VStack {
            HStack(spacing: 4) {
                ForEach(0..<totalStories) { index in
                    THMProgressBarView2(index: index, currentIndex: $currentStoryIndex, storyProgress: $currentStoryProgress)
                }
            }
            .id(totalStories)
            
            THMUserView(
                isMyStory: model.isMyStory,
                image: image,
                name: name,
                date: date) {
                    if model.isMyStory {
                        detailViewModel.showDeleteStoryModal(id: getStory().id) {
                            // Handle story deletion - navigate to next story
                            handleStoryDeletion()
                        } onDismiss: {
                            resumePlayback()
                        }
                    } else {
                        detailViewModel.showProfileOptionsModal(id: model.user.id) {
                            pausePlayback()
                        } onProfileBlock: {
                            
                        } onDismiss: {
                            resumePlayback()
                        }
                    }
                } onDismiss: {
                    dismiss()
                }
            
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        .opacity(hideProfile ? 0.0 : 1.0)
    }
    
    
    private func bottomSection(story: THMStory) -> some View {
        VStack {
            if !hideProfile {
                if model.isMyStory {
                    VStack {
                        if let viewsRef = story.viewsRef, !viewsRef.isEmpty {
                            if viewsRef.count <= 3 {
                                overlapingProfileImagesView(viewsRef: viewsRef)
                            } else {
                                let firstThree = viewsRef[0...2]
                                overlapingProfileImagesView(viewsRef: Array(firstThree))
                            }
                        } else {
                            Rectangle()
                                .fill(.black.opacity(0.001))
                                .frame(width: 35, height: 35)
                        }
                    }
                    .overlay(alignment: story.viewsRef?.isEmpty ?? true ? .center : .top) {
                        Image(systemName: "chevron.up")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .offset(y: story.viewsRef?.isEmpty ?? true ? 0 : -20)
                            .onTapGesture {
                                pausePlayback()
                                detailViewModel.showStoryLikes.toggle()
                            }
                    }
                    .onTapGesture {
                        pausePlayback()
                        detailViewModel.showStoryLikes.toggle()
                    }
                    .animation(.easeInOut, value: hideProfile)
                } else {
                    HStack {
                        TextField(
                            "",
                            text: $messageFieldText,
                            prompt: Text("send_message".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .submitLabel(.send)
                        .onSubmit {
                            sendStoryReply(for: currentStoryIndex)
                        }
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.hmIndigo.opacity(0.5))
                                Capsule()
                                    .stroke(lineWidth: 1)
                                    .fill(.hmIndigo.opacity(0.7))
                            }
                        )

                        Button {
                            sendStoryReply(for: currentStoryIndex)
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .frame(width: 40, height: 40)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(.hmIndigo.opacity(0.5))
                                        Circle()
                                            .stroke(lineWidth: 1)
                                            .fill(.hmIndigo.opacity(0.7))
                                    }
                                )
                        }
                        .disabled(!canSendMessage)
                        .opacity(canSendMessage ? 1 : 0.5)
                        
                        Image(model.stories[currentStoryIndex].isLiked ? "heartfill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .scaleEffect(model.stories[currentStoryIndex].isLiked ? 1.2 : 1.0)
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(.hmIndigo.opacity(0.5))
                                    Circle()
                                        .stroke(lineWidth: 1)
                                        .fill(.hmIndigo.opacity(0.7))
                                }
                            )
                            .onTapGesture {
                                endEditing()
                                model.stories[currentStoryIndex].isLiked.toggle()
                                if let userIndex = viewModel.stories.firstIndex(where: {$0.id == viewModel.currentStoryUser }) {
                                    viewModel.stories[userIndex].stories[currentStoryIndex].isLiked.toggle()
                                }
                                detailViewModel.likeStory(id: model.stories[currentStoryIndex].id)
                            }
                            .animation(.bouncy, value: model.stories[currentStoryIndex].isLiked)
                    }
                    .animation(.easeInOut, value: hideProfile)
                }
            }
            
        }
        .padding(16)
        .animation(messageViewPosition == 0 ? .none : .easeOut)
        .offset(y: messageViewPosition)
    }

    private func sendStoryReply(for index: Int) {
        let trimmedText = trimmedMessageText
        guard !trimmedText.isEmpty else { return }
        guard model.stories.indices.contains(index) else { return }

        let story = model.stories[index]
        detailViewModel.sendMessage(
            message: trimmedText,
            mediaUrl: story.mediaURL,
            storyID: story.id,
            mediaID: story.mediaID,
            username: model.user.username ?? ""
        )
        messageFieldText = ""
        endEditing()
    }
    
    @ViewBuilder
    func getLocationTagOverlay(story: THMStory) -> some View {
        if let placeName = story.location?.placeName,
           let x = story.locationPositionX,
           let y = story.locationPositionY {
            
            let isVideo = story.config.mediaType == .video
            
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text(placeName)
                        .font(.custom(Constants.comicBold, size: 20))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.hmIndigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .black.opacity(0.2), radius: 5)
                )
            }
            .offset(x: x, y: y)
            .zIndex(100)
            .opacity(isVideo ? 1.0 : 0.01) // Invisible for images (baked-in), visible for video
            .onTapGesture {
                // Handle location tap - e.g. open maps
                if let lat = story.location?.lat, let lng = story.location?.lng {
                   let placeNameEncoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                   let url = URL(string: "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(placeNameEncoded)")!
                   if UIApplication.shared.canOpenURL(url) {
                       UIApplication.shared.open(url)
                   }
                }
            }
        }
    }
    
    @ViewBuilder
    func getUserTagOverlay(story: THMStory) -> some View {
        if let username = story.userTagged,
           let userID = story.userTaggedId,
           let x = story.userTaggedPositionX,
           let y = story.userTaggedPositionY {
            
            let isVideo = story.config.mediaType == .video
            
            VStack {
                Text("@\(username)")
                    .font(.custom(Constants.comicBold, size: 20))
                    .foregroundColor(.hmIndigo)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    )
            }
            .offset(x: x, y: y)
            .zIndex(100)
            .opacity(isVideo ? 1.0 : 0.01) // Invisible for images (baked-in), visible for video
            .onTapGesture {
                pausePlayback()
                detailViewModel.navigatingToProfile = true
                detailViewModel.showStoryUserProfile(id: userID)
            }
        }
    }
}
