//
//  MediaPreviewView.swift
//  TheHotelMedia
//
//  Created by MAC on 16/10/24.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Combine

struct PreviewImageRectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


struct MediaPreviewView: View {
    
    var media: MediaType
    var uiImage: UIImage? = nil
    var postID: String? = nil
    var mediaID: String? = nil
    var lastScreen: String = "home"
    @Environment(\.dismiss) var dismiss
    @State var showContent: Bool = false
    @State private var notificationObserver: Any?
    @State var player : AVPlayer?
    @AppStorage("isMute") var isMute: Bool = false
    @State var scale = 1.0
    @State var lastScale = 0.0
    @State var offset: CGSize = .zero
    @State var videoPlayerOffset: CGFloat = 0.0
    @State var lastOffset: CGSize = .zero
    @State var imageFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    @State var transformedFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    @State var likes: String = ""
    @State var shares: String = ""
    @State var comments: String = ""
    @State var likedByMe: Bool? = nil
    @State var savedByMe: Bool? = nil
    
    @State private var isPortrait = true
    
    @StateObject var viewModel = MediaPreviewViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var onPressedLike: ((Bool, Int) -> Void)?
    var onAddingComment: (() -> Void)?
    var onDismiss: (() -> Void)?

    
    init(media: MediaType, image: UIImage? = nil, postID: String? = nil, mediaID: String? = nil, lastScreen: String = "home", likedByMe: Bool? = nil, savedByMe: Bool? = nil, likesCount: Int? = nil, commentsCount: Int? = nil, shareCount: Int? = nil, onPressedLike: ((Bool, Int) -> Void)? = nil, onAddingComment: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.media = media
        self.uiImage = image
        self.postID = postID
        self.mediaID = mediaID
        self.lastScreen = lastScreen
        if let likesCount {
            _likes = State(initialValue: String(likesCount))
        }
        
        if let shareCount {
            _shares = State(initialValue: String(shareCount))
        }
        
        if let commentsCount {
            _comments = State(initialValue: String(commentsCount))
        }
        
        _likedByMe = State(initialValue: likedByMe)
        _savedByMe = State(initialValue: savedByMe)
        self.onPressedLike = onPressedLike
        self.onAddingComment = onAddingComment
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $viewModel.isSharePresented, content: {
            ActivityViewController(activityItems: [viewModel.shareURL])
                .id(viewModel.shareURL)
                .presentationDetents([.medium, .large])
        })
        .overlay {
            VStack {
                if media.isImage && uiImage == nil {
                    WebImage(url: media.url ) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .overlay(alignment: .center) {
                                GeometryReader { geometry in
                                    Color.black.opacity(0.001)
                                        .preference(key: PreviewImageRectPreferenceKey.self, value: geometry.frame(in: .global))
                                }
                            }
                            .onPreferenceChange(PreviewImageRectPreferenceKey.self, perform: { imageFrame in
                                self.imageFrame = imageFrame
                            })
                            .gesture(
                                TapGesture(count: 2) // Double-tap gesture
                                    .onEnded {
                                        withAnimation(.interactiveSpring) {
                                            if scale != 1.0 {
                                                scale = 1.0
                                                lastScale = 1.0
                                            } else {
                                                scale = 2.0
                                                lastScale = 2.0
                                            }
                                            
                                            if offset != .zero {
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                            )
                            .gesture(
                                MagnificationGesture(minimumScaleDelta: 0)
                                    .onChanged({ value in
                                        withAnimation(.interactiveSpring()) {
                                            scale = handleScaleChange(value)
                                        }
                                    })
                                    .onEnded({ _ in
                                        lastScale = scale
                                        let transformedFrame = calculateTransformedFrame(frame: imageFrame, scale: lastScale, offset: lastOffset)
                                        
                                        var newOffset = lastOffset
                                        
                                        if transformedFrame.minX > 0 {
                                            if lastScale == 1 {
                                                newOffset = CGSize(width: 0, height: lastOffset.height)
                                            } else {
                                                let newWidthOffset = ((imageFrame.width * lastScale) - imageFrame.width)/2
                                                newOffset = CGSize(width: newWidthOffset, height: lastOffset.height)
                                            }
                                        }
                                        
                                        if transformedFrame.maxX < Constants.screenWidth {
                                            if lastScale == 1 {
                                                newOffset.width = 0
                                            } else {
                                                let newWidthOffset = ((imageFrame.width * lastScale) - imageFrame.width)/2
                                                newOffset.width = -newWidthOffset
                                            }
                                        }
                                        
                                        if transformedFrame.minY > 0 {
                                            if lastScale > Constants.screenHeight/imageFrame.height {
                                                let newHeightOffset = ((imageFrame.height * lastScale) - Constants.screenHeight)/2
                                                newOffset.height = newHeightOffset
                                            } else {
                                                newOffset.height = 0
                                            }
                                        }
                                        
                                        if transformedFrame.maxY < Constants.screenHeight {
                                            if lastScale > Constants.screenHeight/imageFrame.height {
                                                let newHeightOffset = ((imageFrame.height * lastScale) - Constants.screenHeight)/2
                                                newOffset.height = -newHeightOffset
                                            } else {
                                                newOffset.height = 0
                                            }
                                        }
                                        
                                        withAnimation(.easeInOut) {
                                            offset = newOffset
                                            lastOffset = newOffset
                                        }
                                        
                                    })
                                    .simultaneously(
                                        with: DragGesture(minimumDistance: 0)
                                            .onChanged({ value in
                                                withAnimation(.interactiveSpring()) {
                                                    if scale == 1 {
                                                        offset = handleOffsetChange(CGSize(width: 0, height: value.translation.height), imageFrame: imageFrame)
                                                    } else {
                                                        offset = handleOffsetChange(value.translation, imageFrame: imageFrame)
                                                    }
                                                    
                                                }
                                            })
                                            .onEnded({ value in
                                                let transformedFrame = calculateTransformedFrame(frame: imageFrame, scale: lastScale, offset: offset)
                                                
                                                var newOffset: CGSize = offset
                                                
                                                if transformedFrame.minX > 0 {
                                                    if scale == 1 {
                                                        newOffset.width = 0
                                                    } else {
                                                        let newWidthOffset = ((imageFrame.width * scale) - imageFrame.width)/2
                                                        newOffset.width = newWidthOffset
                                                    }
                                                    
                                                }
                                                
                                                if transformedFrame.maxX < Constants.screenWidth {
                                                    if scale == 1 {
                                                        newOffset.width = 0
                                                    } else {
                                                        let newWidthOffset = ((imageFrame.width * scale) - imageFrame.width)/2
                                                        newOffset.width = -newWidthOffset
                                                    }
                                                }
                                                
                                                if transformedFrame.minY > 0 {
                                                    if scale > Constants.screenHeight/imageFrame.height {
                                                        let newHeightOffset = ((imageFrame.height * scale) - Constants.screenHeight)/2
                                                        newOffset.height = newHeightOffset
                                                    } else {
                                                        newOffset.height = 0
                                                        if scale == 1, value.translation.height > 100 {
                                                            showContent.toggle()
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                                                onDismiss?()
//                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                                                    modifyOrientation(.portrait)
//                                                                }
                                                                dismiss()
                                                                
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                
                                                if transformedFrame.maxY < Constants.screenHeight {
                                                    
                                                    if scale > Constants.screenHeight/imageFrame.height {
                                                        let newHeightOffset = ((imageFrame.height * scale) - Constants.screenHeight)/2
                                                        newOffset.height = -newHeightOffset
                                                    } else {
                                                        newOffset.height = 0
                                                    }
                                                }
                                                
                                                withAnimation(.easeInOut) {
                                                    offset = newOffset
                                                    lastOffset = newOffset
                                                }
                                            })
                                        
                                    )
                            )
                    } placeholder: {
                        CustomProgressView(showIndicator: .constant(true))
                    }
                } else if let uiImage{
                    
                  Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .padding(.horizontal, 12)
                        .gesture(
                            TapGesture(count: 2) // Double-tap gesture
                                .onEnded {
                                    withAnimation(.interactiveSpring) {
                                        if scale != 1.0 {
                                            scale = 1.0
                                            lastScale = 1.0
                                        } else {
                                            scale = 2.0
                                            lastScale = 2.0
                                        }
                                        
                                        if offset != .zero {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            MagnificationGesture(minimumScaleDelta: 0)
                                .onChanged({ value in
                                    withAnimation(.interactiveSpring()) {
                                        scale = handleScaleChange(value)
                                    }
                                })
                                .onEnded({ _ in
                                    lastScale = scale
                                    let transformedFrame = calculateTransformedFrame(frame: imageFrame, scale: lastScale, offset: lastOffset)
                                    
                                    var newOffset = lastOffset
                                    
                                    if transformedFrame.minX > 0 {
                                        if lastScale == 1 {
                                            newOffset = CGSize(width: 0, height: lastOffset.height)
                                        } else {
                                            let newWidthOffset = ((imageFrame.width * lastScale) - imageFrame.width)/2
                                            newOffset = CGSize(width: newWidthOffset, height: lastOffset.height)
                                        }
                                    }
                                    
                                    if transformedFrame.maxX < Constants.screenWidth {
                                        if lastScale == 1 {
                                            newOffset.width = 0
                                        } else {
                                            let newWidthOffset = ((imageFrame.width * lastScale) - imageFrame.width)/2
                                            newOffset.width = -newWidthOffset
                                        }
                                    }
                                    
                                    if transformedFrame.minY > 0 {
                                        if lastScale > Constants.screenHeight/imageFrame.height {
                                            let newHeightOffset = ((imageFrame.height * lastScale) - Constants.screenHeight)/2
                                            newOffset.height = newHeightOffset
                                        } else {
                                            newOffset.height = 0
                                        }
                                    }
                                    
                                    if transformedFrame.maxY < Constants.screenHeight {
                                        if lastScale > Constants.screenHeight/imageFrame.height {
                                            let newHeightOffset = ((imageFrame.height * lastScale) - Constants.screenHeight)/2
                                            newOffset.height = -newHeightOffset
                                        } else {
                                            newOffset.height = 0
                                        }
                                    }
                                    
                                    withAnimation(.easeInOut) {
                                        offset = newOffset
                                        lastOffset = newOffset
                                    }
                                    
                                })
                                .simultaneously(
                                    with: DragGesture(minimumDistance: 0)
                                        .onChanged({ value in
                                            withAnimation(.interactiveSpring()) {
                                                offset = handleOffsetChange(value.translation, imageFrame: imageFrame)
                                            }
                                        })
                                        .onEnded({ _ in
                                            let transformedFrame = calculateTransformedFrame(frame: imageFrame, scale: lastScale, offset: offset)
                                            
                                            var newOffset: CGSize = offset
                                            
                                            if transformedFrame.minX > 0 {
                                                if scale == 1 {
                                                    newOffset.width = 0
                                                } else {
                                                    let newWidthOffset = ((imageFrame.width * scale) - imageFrame.width)/2
                                                    newOffset.width = newWidthOffset
                                                }
                                                
                                            }
                                            
                                            if transformedFrame.maxX < Constants.screenWidth {
                                                if scale == 1 {
                                                    newOffset.width = 0
                                                } else {
                                                    let newWidthOffset = ((imageFrame.width * scale) - imageFrame.width)/2
                                                    newOffset.width = -newWidthOffset
                                                }
                                            }
                                            
                                            if transformedFrame.minY > 0 {
                                                if scale > Constants.screenHeight/imageFrame.height {
                                                    let newHeightOffset = ((imageFrame.height * scale) - Constants.screenHeight)/2
                                                    newOffset.height = newHeightOffset
                                                } else {
                                                    newOffset.height = 0
                                                    if scale == 1 {
                                                        showContent.toggle()
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                                            onDismiss?()
//                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                                                modifyOrientation(.portrait)
//                                                            }
                                                            dismiss()
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            
                                            if transformedFrame.maxY < Constants.screenHeight {
                                                
                                                if scale > Constants.screenHeight/imageFrame.height {
                                                    let newHeightOffset = ((imageFrame.height * scale) - Constants.screenHeight)/2
                                                    newOffset.height = -newHeightOffset
                                                } else {
                                                    newOffset.height = 0
                                                }
                                            }
                                            
                                            withAnimation(.easeInOut) {
                                                offset = newOffset
                                                lastOffset = newOffset
                                            }
                                        })
                                    
                                )
                        )
                } else {
                    Rectangle()
                        .fill(.black)
                        .frame(width: isPortrait ? Constants.screenWidth : Constants.screenHeight, height: isPortrait ? Constants.screenHeight : Constants.screenWidth, alignment: .bottom)
                        .overlay {
//                            VideoPlayer(player: player)
                            PlayerViewControllerRepresentable(player: player, backgroundColor: UIColor(.black))
                                .edgesIgnoringSafeArea(.all)
//                                .controlSize(.mini)
                                .onAppear {
                                    // Add observer for video end
//                                    notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
//                                        // Reset the video back to the start
//                                        player?.seek(to: .zero)
//                                        player?.play() // Optionally auto-play again
//                                    }
//                                    player?.play()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        player?.play()
                                    }
                                }
                                .onDisappear {
                                    // Pause the video
                                    player?.pause()
                                    // Remove observer when the video is no longer visible
//                                    if let observer = notificationObserver {
//                                        NotificationCenter.default.removeObserver(observer)
//                                        notificationObserver = nil // Clear the observer after removal
//                                    }
                                }
//                                .padding(.bottom, 10)
                                .padding(.leading, !isPortrait ? UIApplication.topSafeAreaHeightTHM : 0)
                                .padding(.trailing, !isPortrait ? UIApplication.bottomSafeAreaHeightTHM : 0)
//                                .frame(width: Constants.screenWidth)
                                .frame(width: isPortrait ? Constants.screenWidth : Constants.screenHeight, height: isPortrait ? Constants.screenHeight : Constants.screenWidth)
//                                .offset(y: videoPlayerOffset)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged({ value in
                                    withAnimation(.interactiveSpring) {
                                        videoPlayerOffset = value.translation.height
                                    }
                                })
                                .onEnded({ value in
                                    if value.translation.height > 150 {
                                        showContent = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            onDismiss?()
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                                modifyOrientation(.portrait)
//                                            }
                                            dismiss()
                                        }
                                    } else {
                                        withAnimation(.interactiveSpring) {
                                            videoPlayerOffset = 0
                                        }
                                        showContent = true
                                    }
                                })
                        )
                        
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Rectangle()
                    .fill(.black)
                    .ignoresSafeArea()
            )
            .opacity(showContent ? 1.0 : 0.0)
            .scaleEffect(showContent ? 1.0 : 0.3)
            .animation(.easeInOut(duration: 0.2), value: showContent)
        }
        .overlay(alignment: .bottomTrailing, content: {
            HStack(alignment: .bottom) {
                ZStack {
                    Image(systemName: isPortrait ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 25, height: 25)
                        .shadow(color: .black, radius: 5)
                    
                    Color.black.opacity(0.001)
                }
                .opacity(showContent && !media.isImage ? 1.0 : 0.0)
                .frame(width: 40, height: 40, alignment: .bottomLeading)
                .onTapGesture {
                    if isPortrait {
                        isPortrait = false
                        modifyOrientation(.landscapeLeft)
                    } else {
                        isPortrait = true
                        modifyOrientation(.portrait)
                    }
                }
                .disabled(media.isImage)
                Spacer()
                    .allowsHitTesting(false)
                interactionButtons
                    .background(
                        Color.black.opacity(0.001)
                    )
            }
            .padding()
            .padding(.bottom, 50)
        })
        .overlay(alignment: .topTrailing, content: {
            HStack {
                if media.isImage {
                    Circle()
                        .fill(.hmDarkestGray)
                        .frame(width: 40)
                        .overlay {
                            Image(systemName: "chevron.left" )
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .opacity(showContent ? 1.0 : 0.0)
                        }
                        .offset(x: isPortrait ? 9 : 2 , y: isPortrait ? 10 : 2)
                        .onTapGesture {
                            showContent.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                                onDismiss?()
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                    modifyOrientation(.portrait)
//                                }
                                dismiss()
                            }
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                }
                
                
                if lastScreen == "chat" {
                    Circle()
                        .fill(.hmDarkestGray)
                        .frame(width: 40)
                        .overlay {
                            Image(systemName: "square.and.arrow.up" )
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .opacity(showContent ? 1.0 : 0.0)
                        }
                        .overlay(content: {
                            CustomProgressView(showIndicator: $viewModel.downloadingMedia, dimension: 40, lineWidth: 2, backgroundColor: .clear, type: "growingArc")
                                .allowsHitTesting(false)
                        })
                        .offset(x: 9 , y: 10)
                        .onTapGesture {
                            if media.isImage {
                                viewModel.downloadImage(url: media.url)
                            } else {
                                viewModel.downloadVideo(url: media.url)
                            }
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
        })
        .offset(y: videoPlayerOffset)
        .onAppear {
            showContent = true
            if !media.isImage {
                let playerItem = AVPlayerItem(url: media.url)
                let player = AVPlayer(playerItem: playerItem)
                player.isMuted = isMute
                player.automaticallyWaitsToMinimizeStalling = false
                self.player = player
                
                if let postID, let mediaID {
                    viewModel.viewMedia(postID: postID, mediaID: mediaID)
                }
            }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch(let error) {
                print(error.localizedDescription)
            }
        }
        .onChange(of: isMute) { newValue in
            player?.isMuted = newValue
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Components
extension MediaPreviewView {
    private var interactionButtons: some View {
        VStack {
            if let postID, showContent {
                if let likedByMe, !likes.isEmpty {
                    VStack(spacing: 6) {
                        Image(likedByMe ? "heartfill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .shadow(color: .black, radius: 5)
                        
                        Text(likes)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .onTapGesture {
                        haptics(.medium)
                        if let likesCount = Int(likes) {
                            if self.likedByMe != nil {
                                self.likedByMe?.toggle()
                            }
                            
                            if let likedByMe = self.likedByMe {
                                let newCount = likedByMe ? likesCount + 1 : likesCount - 1
                                likes = String(newCount)
                                onPressedLike?(likedByMe, newCount)
                            }
                        }
                    }
                }
            }
            
            if !comments.isEmpty, showContent {
                VStack(spacing: 6) {
                    Image("comment")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .shadow(color: .black, radius: 5)
                    
                    Text(comments)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .onTapGesture {
                    viewModel.showCommentSection.toggle()
                }
                .sheet(isPresented: $viewModel.showCommentSection, content: {
                    if #available(iOS 16.4, *) {
                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: postID ?? "", totalComments: Int(comments) ?? 0, onAddingComment: { id in
                            if var count = Int(comments) {
                                count += 1
                                comments = String(count)
                                onAddingComment?()
                            }
                            
                        }, onDeletingComment: { id in
                            if var count = Int(comments) {
                                count = max(0, count - 1)
                                comments = String(count)
                            }
                        }), onPressedProfile: { userID in
                            
                        })
                        .environmentObject(themeManager)
                            .presentationDetents([.fraction(0.7), .fraction(0.9)])
                            .presentationBackground(.clear)
                            .presentationDragIndicator(.hidden)
                            .ignoresSafeArea()
                    } else {
                        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: postID ?? "", totalComments: Int(comments) ?? 0, onAddingComment: { id in
                            if var count = Int(comments) {
                                count += 1
                                comments = String(count)
                                onAddingComment?()
                            }
                        }, onDeletingComment: { id in
                            if var count = Int(comments) {
                                count = max(0, count - 1)
                                comments = String(count)
                            }
                        }), onPressedProfile: { userID in
                            
                        })
                        .environmentObject(themeManager)
                            .ignoresSafeArea()
                    }
                })
            }
            
            if !shares.isEmpty, showContent {
                VStack(spacing: 6) {
                    Image("share")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .shadow(color: .black, radius: 5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .onTapGesture {
                    viewModel.showShareView(id: postID ?? "", isEventPost: false)
                }
            }
        }
    }
}


extension MediaPreviewView {
    private func handleScaleChange(_ zoom: CGFloat) -> CGFloat {
        let scale = lastScale + zoom - (lastScale == 0 ? 0 : 1)
        
        if scale > 3 {
            return 3
        } else if scale < 1 {
            return 1
        } else {
            return scale
        }
    }
    
    private func handleOffsetChange(_ offset: CGSize, imageFrame: CGRect) -> CGSize {
        
        
//        let tranformedFrame = calculateTransformedFrame(frame: imageFrame, scale: lastScale, offset: lastOffset)
//        
        var newOffset: CGSize = .zero
//        
//        if (offset.width + tranformedFrame.minX) > 0 {
//            newOffset.width = abs(tranformedFrame.minX)
//        } else {
//            
//        }
//        
//        print(imageFrame)
        newOffset.width = offset.width + lastOffset.width
        newOffset.height = offset.height + lastOffset.height
        
        return newOffset
    }
    
    
    func calculateTransformedFrame(frame: CGRect, scale: CGFloat, offset: CGSize) -> CGRect {
        let newWidth = frame.width * scale
        let newHeight = frame.height * scale
        let originX = frame.origin.x + offset.width - ((newWidth - frame.width) / 2)
        let originY = frame.origin.y + offset.height - ((newHeight - frame.height) / 2)
        
        return CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
    }
}


struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


#Preview {
    MediaPreviewView( media: .video(urlString: ""))
}
