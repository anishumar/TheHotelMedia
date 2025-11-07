//
//  THMStoryDetailView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI

struct THMStoryDetailView: View {
    // MARK: Public Properties
    @ObservedObject var viewModel: THMStoryViewModel
    @StateObject var detailViewModel: THMStoryDetailViewModel
    
    @Binding var onDrag: Bool
    @State var model: THMStoryUIModel
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var timerProgress: CGFloat = 0
    @State var videoPaused: Bool = false
    @State var onChangeStory: Bool = false
    
    let userClosure: THMUserCompletionHandler?
    let onDeleteStory: ((Int) -> Void)?
    let onDismiss: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // MARK: Private Properties
    @ObservedObject private var keyboardManager = KeyboardManager2()
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
    
    private var emojiViewPosition: CGFloat {
        return (messageViewPosition * 1.5)
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            let index = getCurrentIndex()
            let story = model.stories[index]
            
            ZStack(alignment: .bottom) {
                if model.stories.count > index {
                    VStack(spacing: 8) {
                        getStoryView(with: index, story: story)
                            .id(onChangeStory)
                            .sheet(isPresented: $detailViewModel.showStoryLikes, content: {
                                if #available(iOS 16.4, *) {
                                    StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                                        detailViewModel.navigatingToProfile = true
                                        detailViewModel.showStoryLikes.toggle()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                                            detailViewModel.showStoryUserProfile(id: userID)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                            videoPaused = true
                                            pauseVideo()
                                        }
                                    })
                                        .presentationDetents([.fraction(0.8)])
                                        .presentationBackground(.clear)
                                        .presentationDragIndicator(.hidden)
                                        .ignoresSafeArea()
                                } else {
                                    StorySeenView(viewModel: StorySeenViewModel(storyID: story.id), onPressedProfile: { userID in
                                        detailViewModel.navigatingToProfile = true
                                        detailViewModel.showStoryLikes.toggle()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                                            detailViewModel.showStoryUserProfile(id: userID)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                            videoPaused = true
                                            pauseVideo()
                                        }
                                    })
                                        .presentationDetents([.fraction(0.8)])
                                        .presentationDragIndicator(.visible)
                                        .ignoresSafeArea()
                                }
                            })
                            .overlay(
                                tapStory()
                                    .offset(
                                        y: story.config.storyType != .plain()
                                        ? -Constants.MessageView.height : .zero
                                    )
                            )
                            .overlay(content: {
                                if keyboardManager.isKeyboardOpen {
                                    Color.black.opacity(0.001)
                                        .onTapGesture {
                                            endEditing()
                                        }
                                }
                            })
                            .overlay(alignment: .bottom) {
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

                                                    }
                                            }
                                            .onTapGesture {
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
                                                    let index = getCurrentIndex()
                                                    detailViewModel.sendMessage(message: messageFieldText, mediaUrl: model.stories[index].mediaURL, storyID: model.stories[index].id, mediaID: model.stories[index].mediaID, username: model.user.username ?? "")
                                                    messageFieldText = ""
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
                                                
                                                Image(model.stories[index].isLiked ? "heartfill" : "heart")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .scaleEffect(model.stories[index].isLiked ? 1.2 : 1.0)
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
                                                        model.stories[index].isLiked.toggle()
                                                        if let userIndex = viewModel.stories.firstIndex(where: {$0.id == viewModel.currentStoryUser }) {
                                                            viewModel.stories[userIndex].stories[index].isLiked.toggle()
                                                        }
                                                        detailViewModel.likeStory(id: model.stories[index].id)
                                                    }
                                                    .animation(.bouncy, value: model.stories[index].isLiked)
                                            }
                                            .animation(.easeInOut, value: hideProfile)
                                        }
                                    }
                                    
                                }
                                .padding(16)
                                .animation(messageViewPosition == 0 ? .none : .easeOut)
                                .offset(y: messageViewPosition)
                            }
                    }
                }
                getEmojiView(story: story)
            }
            .onAppear {
                print(model.stories)
                detailViewModel.navigatingToProfile = false
            }
            .onDisappear {
                NotificationCenter.default.post(name: .stopAndRestartVideoTHM, object: nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(
                VStack {
                    if !hideProfile {
                        getUserInfoAndProgressBar(with: index)
                            .animation(.easeInOut, value: hideProfile)
                    }
                }
                
                ,alignment: .top
            )
            .overlay {
                CustomProgressView(showIndicator: $detailViewModel.showLoadingIndicator)
            }
            .rotation3DEffect(
                getAngle(proxy: proxy),
                axis: (x: 0, y: 1, z: 0),
                anchor: proxy.frame(in: .global).minX > 0 ? .leading : .trailing,
                perspective: 2.5
            )
        }
        .onChange(of: viewModel.currentStoryUser) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .stopVideoTHM, object: nil)
            }
            
            if model.id == newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    resetProgress()
                    playVideo()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    videoPaused = true
                    pauseVideo()
                }
            }
            
        }
        .onChange(of: onDrag, perform: { newValue in
            if newValue {
                NotificationCenter.default.post(name: .stopVideoTHM, object: nil)
                pauseVideo()
                player.isMuted = true
            }
        })
        .onReceive(timer) { _ in
            if !videoPaused {
                startProgress()
            }
            
        }
        .onReceive(detailViewModel.$showStoryLikes, perform: { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    videoPaused = true
                    pauseVideo()
                }
            } else {
                if !detailViewModel.navigatingToProfile {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        bottomModalDismissed()
                    }
                }
            }
        })
        .onChange(of: isAnimationStarted ? isAnimationStarted : false) { state in
            configureProgress(with: state)
            isTimerRunning = state
        }
        .onReceive(keyboardManager.$isKeyboardOpen, perform: { isOpen in
            if isOpen {
                pauseVideo()
                videoPaused = true
            } else {
                playVideo()
                videoPaused = false
            }
        })
    }
}

// MARK: Private Configuration
private extension THMStoryDetailView {
    
    @ViewBuilder
    func getStoryView(with index: Int, story: THMStory) -> some View {
        switch story.config.mediaType {
        case .image:
            THMImageView(imageURL: story.mediaURL) {
                start(index: index)
            }
            .onAppear {
                resetAVPlayer()
                videoPaused = false
            }
        case .video:
            THMVideoView(
                videoURL: story.mediaURL,
                state: $state,
                player: player
            ) { media, duration in
//                model.stories[index].duration = duration
                if media == .playbackStarted || media == .playbackStopped {
                    
                    videoPaused = media == .playbackStopped
                    
                } else {
                    start(index: index)
                    state = media
                }
                
            } onReadyToPlay: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playVideo()
                }
            }
            .onAppear {
                videoPaused = true
            }
            .onChange(of: state) { _ in
                playVideo()
            }
        }
    }
    
    @ViewBuilder
    func getEmojiView(story: THMStory) -> some View {
        let index = getCurrentIndex()
        switch story.config.storyType {
        case .message(_, let emojis, _):
            if let emojis, showEmoji {
                VStack {
                    Spacer()
                    THMEmojiView(
                        story: getStory(with: index),
                        emojiArray: emojis,
                        startAnimating: $startAnimate,
                        selectedEmoji: $selectedEmoji,
                        userClosure: userClosure
                    )
//                    .animation(messageViewPosition == 0 ? .none : .easeOut)
                    .offset(y: emojiViewPosition)
                    .opacity(messageViewPosition == 0 ? 0 : 1)
                }
                
                if startAnimate {
                    THMEmojiReactionView(
                        dissmis: $startAnimate,
                        isAnimationStarted: $isAnimationStarted,
                        emoji: selectedEmoji
                    )
                }
                
            }
        case .plain:
            Divider()
        }
    }
    
    @ViewBuilder
    func getUserInfoAndProgressBar(with index: Int) -> some View {
        let date = getStory(with: index).date
        let name = model.user.name
        let image = model.user.image
        VStack {
            HStack(spacing: Constants.progressBarSpacing) {
                ForEach(model.stories.indices) { index in
                    THMProgressBarView(
                        timerProgress: timerProgress,
                        index: index
                    )
                }
            }
            .id(model.stories.indices)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            THMUserView(
                isMyStory: model.isMyStory,
                image: image,
                name: name,
                date: date) {
                    if model.isMyStory {
                        detailViewModel.showDeleteStoryModal(id: getStory(with: index).id) {
                            
//                            onDeleteStory?(index)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                            
                        } onDismiss: {
                            bottomModalDismissed()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            videoPaused = true
                            pauseVideo()
                        }
                    } else {
                        detailViewModel.showProfileOptionsModal(id: model.user.id) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                videoPaused = true
                                pauseVideo()
                            }
                            
                        } onProfileBlock: {
                            
                        } onDismiss: {
                            bottomModalDismissed()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            videoPaused = true
                            pauseVideo()
                        }
                    }
                } onDismiss: {
                    dismiss()
                }

        }
    }
    
    @ViewBuilder
    func messageView(with index: Int) -> some View {
        let story = getStory(with: index)
        
        THMMessageView(
            story: story,
            showEmoji: $showEmoji,
            userClosure: userClosure
        )
        .padding()
        .animation(messageViewPosition == 0 ? .none : .easeOut)
        .offset(y: messageViewPosition)
    }
    
    @ViewBuilder
    func tapStory() -> some View {
        HStack {
            Rectangle()
                .fill(.black.opacity(0.01))
                .onLongPressGesture(minimumDuration: 0.3, perform: {
//                    longPressStarted = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        longPressStarted = true
//                    }
                    
                }, onPressingChanged: { isPressing in
                    if !isPressing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            longPressStarted = false
                        }
                        longPressStarted = false
                    } else {
                        longPressStarted = true
                    }
//                    if !isPressing {
//                        longPressTask?.cancel()
////                        longPressTask = nil
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                            if videoPaused {
//                                longPressStarted = false
//                            }
//                            
//                        }
//                    } else {
//                        longPressTask = Task {
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                            await MainActor.run {
//                                longPressStarted = true
//                            }
//                        }
//                    }
                })
                .onTapGesture {
                    //                    pauseVideo()
                    tapPreviousStory()
                }
            
            
            Rectangle()
                .fill(.black.opacity(0.01))
                .onLongPressGesture(minimumDuration: 0.3, perform: {
//                    longPressStarted = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        longPressStarted = true
//                    }
                    
                }, onPressingChanged: { isPressing in
                    if !isPressing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            longPressStarted = false
                        }
                        longPressStarted = false
                    } else {
                        longPressStarted = true
                    }
//                    if !isPressing {
//                        longPressTask?.cancel()
////                        longPressTask = nil
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                            if videoPaused {
//                                longPressStarted = false
//                            }
//                        }
//                    } else {
//                        longPressTask = Task {
//                            try? await Task.sleep(nanoseconds: 500_000_000)
//                            await MainActor.run {
//                                longPressStarted = true
//                            }
//                        }
//                    }
                })
                .onTapGesture {
                    //                    pauseVideo()
                    tapNextStory()
                }
            
        }
        .onChange(of: longPressStarted) { newValue in
            if newValue {
                pauseVideo()
                videoPaused = true
                hideProfile = true
            } else {
                playVideo()
                videoPaused = false
                hideProfile = false
            }
        }
    }
    
    func getAngle(proxy: GeometryProxy) -> Angle {
        let rotation: CGFloat = 45
        let progress = proxy.frame(in: .global).minX / proxy.size.width
        let degrees = rotation * progress
        return Angle(degrees: degrees)
    }
    
    func resetProgress() {
        timerProgress = 0
    }
    
    func getPreviousStory() {
        
        if let first = viewModel.stories.first, first.id != model.id {

            let bundleIndex = viewModel.stories.firstIndex { currentBundle in
                return model.id == currentBundle.id
            } ?? 0
            
            withAnimation {
                viewModel.currentStoryUser = viewModel.stories[bundleIndex - 1].id
//                onChangeStoryUser?(bundleIndex - 1)
            }
        } else {
            let index = getCurrentIndex()
            let story = getStory(with: index)
            if story.config.mediaType == .video {
                NotificationCenter.default.post(name: .stopAndRestartVideoTHM, object: nil)
                resetProgress()
            }
        }
        onChangeStory.toggle()
        return
    }
    
    
    func getNextStory() {
        
        let index = getCurrentIndex()
        let story = getStory(with: index)
        
        if let last = model.stories.last, last.id == story.id {
            if let lastBundle = viewModel.stories.last, lastBundle.id == model.id {
                withAnimation {
                    dismiss()
                }
            } else {
                let bundleIndex = viewModel.stories.firstIndex { currentBundle in
                    return model.id == currentBundle.id
                } ?? 0
                withAnimation {
                    viewModel.currentStoryUser = viewModel.stories[bundleIndex + 1].id
//                    model = viewModel.stories[bundleIndex + 1]
//                    onChangeStoryUser?(bundleIndex + 1)
                }
            }
        }
        onChangeStory.toggle()
    }
    
    func startProgress() {
        guard !isTimerRunning else { return }
        
        let index = getCurrentIndex()
        let story = getStory(with: index)
        
        if !story.isViewed {
            model.stories[index].isViewed = true
            if !model.isMyStory {
                detailViewModel.viewStory(id: story.id)
            }
        }
        
        
        if viewModel.currentStoryUser == model.id {
            if !model.isSeen {
                model.isSeen = true
            }
            if timerProgress < CGFloat(model.stories.count) {
                if story.isReady {
                    getProgressBarFrame(duration: story.duration)
                }
            } else {
                updateStory()
            }
        }
    }
    
    func updateStory(direction: THMStoryDirectionEnum = .next) {
        if direction == .previous {
            getPreviousStory()
        } else {
            getNextStory()
        }
    }
    
    func tapNextStory() {
        configureTapScreen()
        guard !isTapDisabled else { return }
        if (timerProgress + 1) > CGFloat(model.stories.count) {
            //next user
            updateStory()
        } else {
            //next Story
            timerProgress = CGFloat(Int(timerProgress + 1))
        }
    }
    
    func tapPreviousStory() {
        configureTapScreen()
        guard !isTapDisabled else { return }
        if (timerProgress - 1) < 0 {
//            updateStory(direction: .previous)
            resetProgress()
            let index = getCurrentIndex()
            let story = getStory(with: index)
            if story.config.mediaType == .video {
                NotificationCenter.default.post(name: .stopAndRestartVideoTHM, object: nil)
                resetProgress()
            }
        } else {
            timerProgress = CGFloat(Int(timerProgress - 1))
        }
    }
    
    func start(index: Int) {
        if !model.stories[index].isReady {
            model.stories[index].isReady = true
        }
    }
    
    func getProgressBarFrame(duration: Double) {
        let calculatedDuration = viewModel.getVideoProgressBarFrame(duration: duration)
        timerProgress += (0.01 / calculatedDuration)
    }
    
    func dismiss() {
        onDismiss?()
        detailViewModel.dismissScreen()
        NotificationCenter.default.post(name: .replaceCurrentItemTHM, object: nil)
    }
    
    func getCurrentIndex() -> Int {
//        if timerProgress.isFinite {
//                return min(Int(timerProgress), model.stories.count - 1)
//            } else {
//                // Handle the case where the double value is NaN or infinite
//                print("Cannot convert \(timerProgress) to Int because it is NaN or infinite.")
//                return model.stories.count - 1
//            }
        return min(Int(floor(timerProgress)), model.stories.count - 1)
        
    }
    
    func getStory(with index: Int) -> THMStory {
        return model.stories[index]
    }
    
    func resetAVPlayer() {
        Task {
            player.pause()
        }
        player = AVPlayer()
    }
    
    func pauseVideo() {
        player.pause()
    }
    
    func playVideo() {
        let index = getCurrentIndex()
        let currentUser = viewModel.currentStoryUser == model.id
        let video = model.stories[index].config.mediaType == .video
        let isReady = state == .ready || state == .started
        
        if isReady, currentUser, video {
            player.automaticallyWaitsToMinimizeStalling = false
            player.play()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            player.play()
        }
    }
    
    func configureTapScreen() {
        switch (keyboardManager.isKeyboardOpen, isAnimationStarted) {
        case (true, _):
            isTapDisabled = true
        case (false, true):
            isTapDisabled = true
        default:
            isTapDisabled = false
        }
    }
    
    func configureProgress(with state: Bool) {
        let index = getCurrentIndex()
        let story = model.stories[index]
        let mediaType = story.config.mediaType
        if state, mediaType == .video {
            pauseVideo()
        } else if !state, mediaType == .video {
            guard viewModel.currentStoryUser == model.id else { return }
            playVideo()
        }
    }
    
    
    func bottomModalDismissed() {
        videoPaused = false
        playVideo()
    }
}


extension THMStoryDetailView {
    
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
}

