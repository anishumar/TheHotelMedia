//
//  PostContentView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/05/25.
//

import SwiftUI
import AVKit
import SDWebImageSwiftUI

struct PostContentView: View {
    
    let postType: String
    var onTapMedia: ((Int) -> Void)? = nil
    var onTapReview: ((String) -> Void)? = nil
    var onUserNotFound: (() -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedEvent: ((String) -> Void)? = nil
    @EnvironmentObject var viewModel: GenericPostViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State var avplayers: [AVPlayer?] = []
    @State var isPausedArray: [Bool] = []
    @State var currentPage: Int = 0
    @State var coverImage: String = ""
    @State var firstImage: String = ""
    @State private var notificationObserver: Any?
    @State var isMute: Bool = false
    
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if avplayers.isNotEmpty, postType == "post" {
                postContentView
            } else if postType == "review" {
                reviewContentView
            } else if postType == "event" {
                eventContentView
                    .onTapGesture {
                        onPressedEvent?(viewModel.postData?.id ?? "")
                    }
            }
            
            if avplayers.count > 1 {
                HStack(spacing: 4) {
                    ForEach(viewModel.mediaContent, id: \.url) { media in
                        if let index = viewModel.mediaContent.firstIndex(where: {$0.url == media.url}) {
                            Circle()
                                .fill(currentPage == index ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.lightGray_mediumGray)
                                .frame(width: 4)
                        }
                    }
                }
            }
        }
//        .frame(maxWidth: .infinity)
//        .frame(height: ((postType == "review" ? 290 : Constants.screenWidth - 36) + (avplayers.count > 1 ? 12 : 0)))
        .onReceive(viewModel.coverImage2) { newValue in
            guard newValue.isNotEmpty else { return }
            coverImage = newValue
        }
        .onReceive(viewModel.firstImage2) { newValue in
            guard newValue.isNotEmpty else { return }
            firstImage = newValue
        }
        .onReceive(viewModel.isPauseArray2) { newValue in
            guard newValue.isNotEmpty else { return }
            isPausedArray = newValue
        }
        .onReceive(viewModel.avplayers2) { newValue in
            guard newValue.isNotEmpty else { return }
            avplayers = newValue
        }
        .onChange(of: currentPage) { newValue in
            guard postType == "post" else { return }
            let isPaused = viewModel.isPausePost2.value
            
            var array: [Bool] = []
            
            guard !isPausedArray.isEmpty else { return }
            
            for _ in 0..<isPausedArray.count {
                array.append(true)
            }
            if !isPaused {
                array[newValue] = false
            }
            
            self.isPausedArray = array
        }
        .onReceive(viewModel.isPausePost2) { isPaused in
            guard postType == "post" else { return }
            var array: [Bool] = []
            
            guard !isPausedArray.isEmpty else { return }
            
            for _ in 0..<isPausedArray.count {
                array.append(true)
            }
            if !isPaused {
                array[currentPage] = false
            }
            
            self.isPausedArray = array
        }
        .onChange(of: isPausedArray) { bools in
            for (index, bool) in bools.enumerated() {
                if bool {
                    avplayers[index]?.pause()
                } else {
                    avplayers[index]?.play()
                }
            }
        }
    }
}

// MARK: - Components
extension PostContentView {
    private var postContentView: some View {
        ZStack {
//            WebImage(url: URL(string: viewModel.firstImage ?? "")) { image in
//                image
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: Constants.screenWidth - 38)
//                    .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//            } placeholder: {
//                Image("PostImagePlaceholder")
//                    .resizable()
//                    .scaledToFit()
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//            }
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: Constants.screenWidth - 36)
        }
        .allowsHitTesting(false)
        .opacity(0)
        .overlay(
            VStack {
                if avplayers.isNotEmpty {
                    TabView(selection: $currentPage) {
                        if avplayers.isNotEmpty {
                            ForEach(viewModel.postData?.mediaRef ?? []) { media in
                                if let index = viewModel.postData?.mediaRef?.firstIndex(where: {$0.id == media.id}) {
                                    if media.mediaType == "image" {
                                        imageSection2(media: media, index: index)
                                            .tag(index)
                                    } else {
                                        videoSection(media: media, index: index)
                                            .tag(index)
                                            .onReceive(viewModel.isPausePost2, perform: { newValue in
                                                guard !newValue else { return }
                                                isMute = UserDefaultsManager.shared.getMuteStatus()
                                                avplayers[index]?.isMuted = isMute
                                            })
                                            .onAppear {
                                                isMute = UserDefaultsManager.shared.getMuteStatus()
                                                avplayers[index]?.isMuted = isMute
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onReceive(timer) { _ in
                        if !viewModel.isPausePost2.value {
                            avplayers[currentPage]?.play()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
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
                            .frame(width: Constants.screenWidth - 38)
                            .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .allowsHitTesting(false)
                    }, placeholder: {
                        Image("CoverPlaceholder")
                            .resizable()
                            .scaledToFit()
                    })
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            
            
        }
        .onTapGesture {
            if let postID = viewModel.postData?.id {
                onTapReview?(postID)
            }
        }
        .overlay(
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
//                    .fill(.ultraThinMaterial)
//                    .preferredColorScheme(.dark)
                    .frame(height: 80)
                secondProfileDetailView
                    .onTapGesture {
                        if let googleReviewedBusiness = viewModel.postData?.googleReviewedBusiness {
                            guard googleReviewedBusiness.isEmpty else {
                                onUserNotFound?()
                                return
                            }
                            if let userID = viewModel.postData?.reviewedBusinessProfileRef?.userID {
                                onPressedProfile?(userID)
                            }
                        } else if viewModel.postData?.googleReviewedBusiness == nil {
                            if let userID = viewModel.postData?.reviewedBusinessProfileRef?.userID {
                                onPressedProfile?(userID)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }
            
            .clipShape(RoundedRectangle(cornerRadius: 14))
            , alignment: .top
        )
        .overlay(
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
//                    .fill(.ultraThinMaterial)
                    .frame(height: 45)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                HStack {
                    HStack(spacing: 12) {
                        ForEach(0..<Int(viewModel.postData?.rating ?? 0)) { index in
                            FractionalStar(fraction: 1)
                                .frame(width: 20, height: 20)
                        }
                        
                        ForEach(0..<5 - Int(viewModel.postData?.rating ?? 0)) { index in
                            FractionalStar(fraction: 0)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .id(viewModel.postData?.rating)
                    Spacer()
                    
                    if let rating = viewModel.postData?.rating {
                        Text(rating == 1 ? "😢" : rating == 2 ? "🙁" : rating == 3 ? "😑" : rating == 4 ? "🙂" : "😍")
                            .font(.custom(Constants.comicFont, size: 20))
                    }
                    
                }
                .padding(.bottom, 12.5)
                .padding(.horizontal, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }
    
    
    private var eventContentView: some View {
        
        Rectangle()
            .frame(maxWidth: .infinity)
            .frame(height: Constants.screenWidth - 36)
            .overlay {
                WebImage(url: URL(string: firstImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image("PostImagePlaceholder")
                        .resizable()
                        .scaledToFill()
                        
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
//        ZStack {
//            WebImage(url: URL(string: firstImage)) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//                    .frame(width: Constants.screenWidth - 38)
//                    .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
//            } placeholder: {
//                Image("PostImagePlaceholder")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .clipShape(RoundedRectangle(cornerRadius: 14))
//            }
//        }
    }
}


// MARK: - Smaller Components
extension PostContentView {
    private func imageSection2(media: MediaRef, index: Int) -> some View {
        VStack {
            WebImage(url: URL(string: media.sourceURL ?? "")) { image in
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .overlay {
                        image
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .onTapGesture {
                        onTapMedia?(index)
                    }
                
            } placeholder: {
                WebImage(url: URL(string: media.thumbnailURL ?? "")!)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
            }

        }
    }
    
    
    private func videoSection(media: MediaRef, index: Int) -> some View {
        Rectangle()
            .fill(themeManager.currentTheme.backgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                WebImage(url: URL(string: media.thumbnailURL ?? "")!)
                    .resizable()
                    .scaledToFill()
//                    .opacity(isPaused ? 1.0 : 0.0)
                
            }
            .overlay(content: {
                CustomVideoPlayer(player: avplayers[index]) {
                    
                }
                onRateChange: { rate in
                    guard index == currentPage else { return }
                    viewModel.rate = rate
                }
                .onAppear {
                    notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: avplayers[index]?.currentItem, queue: .main) { _ in
                        // Reset the video back to the start
                        avplayers[index]?.seek(to: .zero)
                        avplayers[index]?.play() // Optionally auto-play again
                    }
                }
                .onDisappear {
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                        notificationObserver = nil // Clear the observer after removal
                    }
                }
            })
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture {
                onTapMedia?(index)
            }
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
            .onChange(of: isMute) { newValue in
                avplayers[index]?.isMuted = newValue
                UserDefaultsManager.shared.setMuteStatus(newValue)
                if !newValue {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                    } catch(let error) {
                        print(error.localizedDescription)
                    }
                } else {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                    } catch(let error) {
                        print(error.localizedDescription)
                    }
                }
            }
            
    }
    
    
    private var secondProfileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.postData?.reviewedBusinessProfileRef?.profilePic?.small ?? "")
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.postData?.reviewedBusinessProfileRef?.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.label)
                
                let rating = viewModel.postData?.reviewedBusinessProfileRef?.rating
                let type = viewModel.postData?.reviewedBusinessProfileRef?.businessTypeRef?.name ?? ""
                let subType = viewModel.postData?.reviewedBusinessProfileRef?.businessSubtypeRef?.name ?? ""
                
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
