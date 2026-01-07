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
    @State var timerProgress: CGFloat = 0
    @State var videoPaused: Bool = false
    @State var onChangeStory: Bool = false
    @State var watchingCurrentUser: Bool = false
    @State var loadingVideo: Bool = false
    @State var stopProgress: Bool = false
    @State var currentStoryIndex: Int = 0
    @State var totalStories: Int = 1
    @State var currentStoryDuration: Double = 15
    @State var currentStoryProgress: Float = 0
    @State var toIncreaseProgress: Double = 0
    
    
    let userClosure: THMUserCompletionHandler?
    let onDeleteStory: ((Int) -> Void)?
    let onDismiss: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: Private Properties
    @StateObject private var keyboardManager = KeyboardManager2()
    @State private var state: THMMediaState = .notStarted
    @State private var player = AVPlayer()
    @State private var animate = false
    @State private var selectedEmoji = ""
    @State private var startAnimate = false
    @State private var isTimerRunning: Bool = false
    @State private var isAnimationStarted: Bool = false
    @State private var isTapDisabled: Bool = false
    @State private var showEmoji: Bool = true
    @State private var showBlockModalView: Bool = false
    @State private var messageFieldText: String = ""
    @State private var hideProfile: Bool = false
    @State private var manualPaused: Bool = false
    @State private var longPressStarted: Bool = false
    @GestureState private var longPress: Bool = false
    
    @State private var longPressTask: Task<Void, Never>?
    
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
            VStack {
                let story = model.stories[currentStoryIndex]
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
                    startVideo()
                }, content: {
                    if #available(iOS 16.4, *) {
                        StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                            detailViewModel.navigatingToProfile = true
                            detailViewModel.showStoryLikes.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                stopVideo()
                                resetPlayer()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 ) {
                                detailViewModel.showStoryUserProfile(id: userID)
                            }
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.8)])
                        .presentationBackground(.clear)
                        .presentationDragIndicator(.hidden)
                        .ignoresSafeArea()
                    } else {
                        StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                            detailViewModel.navigatingToProfile = true
                            detailViewModel.showStoryLikes.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                stopVideo()
                                resetPlayer()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 ) {
                                detailViewModel.showStoryUserProfile(id: userID)
                            }
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.8)])
                        .presentationDragIndicator(.visible)
                        .ignoresSafeArea()
                    }
                })
                .overlay {
                    CustomProgressView(showIndicator: $loadingVideo)
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
            }
            .onReceive(viewModel.$currentStoryUser) { id in
                if id == model.id {
                    watchingCurrentUser = true
                } else {
                    stopVideo()
                    resetPlayer()
                    watchingCurrentUser = false
                }
            }
            .onReceive(timer, perform: { _ in
                if !stopProgress {
                    currentStoryProgress += Float(toIncreaseProgress)
                    
                    if currentStoryProgress >= 100 {
                        tapNextStory()
                    }
                }
            })
            .onReceive(keyboardManager.$isKeyboardOpen, perform: { value in
                if value {
                    stopVideo()
                } else {
                    startVideo()
                }
            })
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewModel.currentStoryUser = model.id
                    currentStoryIndex = 0
                    totalStories = model.stories.count
                    configureProgress()
                    

                }
            }
            .rotation3DEffect(
                getAngle(proxy: proxy),
                axis: (x: 0, y: 1, z: 0),
                anchor: proxy.frame(in: .global).minX > 0 ? .leading : .trailing,
                perspective: 2.5
            )
            .onChange(of: onDrag) { newValue in
                if newValue {
                    stopVideo()
                } else {
                    startVideo()
                }
            }
        }
        
    }
}

// MARK: - Functions
extension THMStoryDetailView2 {
    func tapNextStory() {
        if currentStoryIndex < totalStories - 1{
            currentStoryIndex += 1
        } else {
            toNextUser()
        }
        resetPlayer()
        onChangeStory.toggle()
        configureProgress()
    }
    
    func tapPreviousStory() {
        if currentStoryIndex <= 0 {
            toPreviousUser()
        } else {
            currentStoryIndex -= 1
        }
        resetPlayer()
        onChangeStory.toggle()
        configureProgress()
    }
    
    
    func getAngle(proxy: GeometryProxy) -> Angle {
        let rotation: CGFloat = 45
        let progress = proxy.frame(in: .global).minX / proxy.size.width
        let degrees = rotation * progress
        return Angle(degrees: degrees)
    }
    
    
    func configureProgress() {
        let story = model.stories[currentStoryIndex]
        
        currentStoryDuration = story.duration
        currentStoryProgress = 0
        toIncreaseProgress = 100 / (currentStoryDuration * 10)
    }
    
    
    func getStory() -> THMStory {
        return model.stories[currentStoryIndex]
    }
    
    
    func dismiss() {
        onDismiss?()
        resetPlayer()
        detailViewModel.dismissScreen()
    }
    
    
    func startVideo() {
        detailViewModel.pauseVideo = false
        stopProgress = false
    }
    
    func stopVideo() {
        detailViewModel.pauseVideo = true
        stopProgress = true
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
    
    
    func resetPlayer() {
        stopVideo()
        player.replaceCurrentItem(with: nil)
        player = AVPlayer()
    }
    
    
    func updatePlayer() {
        if let url = URL(string: model.stories[currentStoryIndex].mediaURL) {
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
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
}


// MARK: - Components
extension THMStoryDetailView2 {
    private func storyImageView(urlString: String) -> some View {
        Rectangle()
            .fill(themeManager.currentTheme.backgroundColor)
            .overlay {
                WebImage(url: URL(string: urlString)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                loadingVideo = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                stopProgress = false
                                updateStoryView()
                            }
                        }
                } placeholder: {
                    Rectangle()
                        .fill(.black)
                }

            }
            .clipped()
            .onAppear {
                loadingVideo = true
            }
    }
    
    
    private func storyVideoView(urlString: String) -> some View {
        VStack {
            if let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encodedUrlString) {
                CustomVideoPlayer(player: player, contentMode: .resizeAspect, backgroundColor: UIColor(themeManager.currentTheme.backgroundColor)) {
                    player.play()
                } onTimeControlStatusChange: { status in
                    switch status {
                    case .paused:
                        DispatchQueue.main.async {
                            stopProgress = true
                        }
                    case .waitingToPlayAtSpecifiedRate:
                        DispatchQueue.main.async {
                            stopProgress = true
                            loadingVideo = true
                        }
                    case .playing:
                        DispatchQueue.main.async {
                            stopProgress = false
                            loadingVideo = false
                        }
                    @unknown default:
                        break
                    }
                }
                .onReceive(detailViewModel.$pauseVideo) { value in
                    if value {
                        player.pause()
                    } else {
                        player.play()
                    }
                }
                .onAppear {
                    let playerItem = AVPlayerItem(url: url)
                    player = AVPlayer(playerItem: playerItem)
                    player.automaticallyWaitsToMinimizeStalling = false
                    
                    // Get actual video duration and update story duration
                    Task {
                        let asset = AVURLAsset(url: url)
                        let duration = try? await asset.load(.duration)
                        let durationInSeconds = duration.map { CMTimeGetSeconds($0) } ?? 15.0
                        
                        await MainActor.run {
                            // Use actual video duration, but ensure minimum 15 seconds
                            let actualDuration = max(durationInSeconds, 15.0)
                            if actualDuration > currentStoryDuration {
                                currentStoryDuration = actualDuration
                                toIncreaseProgress = 100 / (currentStoryDuration * 10)
                            }
                        }
                    }
                    
                    updateStoryView()
                }
                .onDisappear {
                    player = AVPlayer()
                }
            } else {
                Text("Error: Invalid Video URL")
                    .foregroundColor(.white)
                    .onAppear {
                        print("❌ Invalid Story Video URL: \(urlString)")
                    }
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
                    if !isPressing {
                        startVideo()
                        hideProfile = false
                    } else {
                        stopVideo()
                        hideProfile = true
                    }
                })
                .onTapGesture {
                    tapPreviousStory()
                }
            Rectangle()
                .fill(.black.opacity(0.001))
                .onLongPressGesture(minimumDuration: 0.3, perform: {
                    
                }, onPressingChanged: { isPressing in
                    if !isPressing {
                        startVideo()
                        hideProfile = false
                    } else {
                        stopVideo()
                        hideProfile = true
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
                            
//                            onDeleteStory?(index)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                            
                        } onDismiss: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                startVideo()
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            stopVideo()
                        }
                    } else {
                        detailViewModel.showProfileOptionsModal(id: model.user.id) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                stopVideo()
                            }
                            
                        } onProfileBlock: {
                            
                        } onDismiss: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                startVideo()
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            stopVideo()
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
                                detailViewModel.showStoryLikes.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    stopVideo()
                                }
                            }
                    }
                    .onTapGesture {
                        detailViewModel.showStoryLikes.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            stopVideo()
                        }
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
                detailViewModel.navigatingToProfile = true
                stopVideo()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    detailViewModel.showStoryUserProfile(id: userID)
                }
            }
        }
    }
}
