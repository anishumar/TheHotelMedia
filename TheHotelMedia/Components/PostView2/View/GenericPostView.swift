//
//  GenericPostView.swift
//  TheHotelMedia
//
//  Created by MAC on 29/01/25.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit
import ActivityIndicatorView
import Combine

struct MediaVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct GenericPostView: View {
    
    @Binding var isPaused: Bool
    @Binding var postData: PostData
    var index: Int? = nil
    
    @StateObject var viewModel: GenericPostViewModel
    var onCommentPressed: ((String) -> Void)?
    var onPressedComment: ((String) -> Void)? = nil
    var onPressedShare: ((String, String) -> Void)? = nil
    var onPressedEllpsis: ((String) -> Void)? = nil
    var onPressedLike: (() -> Void)? = nil
    var onPressedBookmark: (() -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    var onPaused: (() -> Void)?
    var onAddingComment: ((Int) -> Void)? = nil
    var onPressedUrl: ((URL) -> Void)? = nil
    var onTapMedia: ((Int) -> Void)? = nil
    var onTapReview: ((String) -> Void)? = nil
    var onUserNotFound: (() -> Void)? = nil
    var onPressedJoin: ((String) -> Void)? = nil
    var onPressedEvent: ((String) -> Void)? = nil
    var onPlayVideo:((CGRect, String, URL) -> Void)? = nil
    var onPressedCross: ((String) -> Void)? = nil
    var onViewAll: (() -> Void)? = nil
    var hideVideo: ((Bool) -> Void)? = nil
    var onPressedTag: (([TaggedRef]) -> Void)? = nil
    var onClearVideo: (() -> Void)? = nil
    
    @State var suggestionData: [ReviewedBusinessProfileRef] = []
    @State private var isExpanded: Bool = false
    @State private var showLocation: Bool = true
    @State var skip: Bool = true
    @State var uiImage: UIImage? = nil
    @State var isMute: Bool = true
    @State private var notificationObserver: Any?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var listViewModel: PostViewModel2
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.displayScale) var displayscale
    
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if postData.postType == "suggestion" {
                VStack {
                    if !suggestionData.isEmpty {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Suggested for You")
                                    .withComicFont(14, color: themeManager.currentTheme.label)
                                Spacer()
                                Text("View all")
                                    .withComicFont(12, color: themeManager.currentTheme.label)
                                    .onTapGesture {
                                        onViewAll?()
                                    }
                            }
                            .padding(.horizontal, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(suggestionData) { suggestion in
                                        SuggestionCard(suggestion: suggestion) { id in
                                            onPressedProfile?(id)
                                        } onPressedCross: { id in
                                            if let index = suggestionData.firstIndex(where: {$0.id == id}) {
                                                suggestionData.remove(at: index)
                                            }
                                            onPressedCross?(id)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: Constants.screenHeight * 0.25)
                        .scaleEffect(y: suggestionData.isEmpty ? 0 : 1.0)
                    }
                }
        //        .id(suggestionData)
                .onReceive(viewModel.$postData, perform: { newValue in
                    suggestionData = newValue?.data ?? []
                })
                .onAppear {
                    suggestionData = viewModel.postData?.data ?? []
                }
            } else {
                VStack(spacing: 12) {
                    profileDetailView
                        .onTapGesture {
                            if let id = viewModel.postData?.postedBy?.id {
                                onPressedProfile?(id)
                            }
                        }
                        .padding(.bottom, 4)
                    
                    VStack {
                        if !viewModel.mediaContent.isEmpty, postData.postType == "post" {
                            postContentView
                        } else if postData.postType == "review" {
                            reviewContentView
                        } else if postData.postType == "event" {
                            eventContentView
                                .onTapGesture {
                                    onPressedEvent?(viewModel.postData?.id ?? "")
                                }
                        }
                    }
                    
                    if viewModel.mediaContent.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(viewModel.postData?.mediaRef ?? []) { media in
                                if let index = viewModel.postData?.mediaRef?.firstIndex(where: {$0.id == media.id}) {
                                    Circle()
                                        .fill(viewModel.currentPage == index ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.lightGray_mediumGray)
                                        .frame(width: 4)
                                   
                                }
                            }
                        }
                    }
//                    
//                    PostContentView(postType: postData.postType ?? "", onTapMedia: { index in
//                        isPaused = true
//                        onTapMedia?(index)
//                        
//                    }, onTapReview: { postID in
//                        onTapReview?(postID)
//                        
//                    }, onUserNotFound: {
//                        onUserNotFound?()
//                        
//                    }, onPressedProfile: { userID in
//                        onPressedProfile?(userID)
//                        
//                    }, onPressedEvent: { postID in
//                        onPressedEvent?(postID)
//                        
//                    })
//                    .environmentObject(viewModel)
//                    .environmentObject(themeManager)
                    
                    if postData.postType == "event" {
                        eventDescription
                    } else {
                        ZStack {
                            if !(viewModel.postData?.content ?? "").isEmpty || !viewModel.feeling.isEmpty || !viewModel.taggedRef.isEmpty || !viewModel.location.isEmpty {
                                description
                                    .offset(y: viewModel.mediaContent.isEmpty ? -6 : 0)
                            }
                        }
                    }
                    
                    
                    divider
                    ZStack {
                        HStack(spacing: 6) {
                            if viewModel.postData?.postType == "event", viewModel.isValidEvent {
                                joinButton
                                    .onTapGesture {
                                        withAnimation(.smooth) {
                //                            isJoining.toggle()
                                            viewModel.isJoining.toggle()
                                            postData.imJoining?.toggle()
                                            onPressedJoin?(viewModel.postData?.id ?? "")
                                        }
                                        
                                    }

                            } else if viewModel.postData?.postType != "event" {
                                HStack(spacing: 6) {
                                    Image(viewModel.likedByMe ? "heartfill" : themeManager.currentTheme.heart)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                        .scaleEffect(viewModel.heartScale)
                                    
                                    Text(viewModel.formatNumber(Double(viewModel.likes ?? 0)))
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
                                    
                                    if postData.likes != nil, viewModel.likes != nil {
                                        if viewModel.likedByMe {
                                            postData.likes! -= 1
                                            viewModel.likes! -= 1
                                        } else {
                                            postData.likes! += 1
                                            viewModel.likes! += 1
                                        }
                                    }
                                    
                                    postData.likedByMe?.toggle()
                                    viewModel.likedByMe.toggle()
                                    onPressedLike?()
                                }
                            }
                            
                            
                            
                            HMCustomButton2(icon: themeManager.currentTheme.comment, count: viewModel.formatNumber(Double(postData.comments ?? 0)))
                                .onTapGesture {
                                    haptics(.light)
                                    onCommentPressed?(viewModel.postData?.id ?? "")
                                }
                            HMCustomButton2(icon: themeManager.currentTheme.share, count: viewModel.formatNumber(Double(postData.shared ?? 0)))
                                .onTapGesture {
                                    haptics(.light)
                                    onPressedShare?(viewModel.postData?.id ?? "", viewModel.postData?.postedBy?.name ?? "")
                                }
                            
                            if let views = postData.views, views > 0 {
                                HMCustomButton(icon: .constant(themeManager.currentTheme.eye3), count: .constant(Double(views).formatNumber()))
                            }
                            
                            Spacer()
                            Image(viewModel.savedByMe ? "bookmarkfill" : themeManager.currentTheme.bookmark)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
                                .animation(.none, value: viewModel.savedByMe)
                                .onTapGesture {
                                    haptics(.light)
                                    postData.savedByMe?.toggle()
                                    viewModel.savedByMe.toggle()
                                    onPressedBookmark?()
                                }
                            
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .background(
                    CustomShape4()
                        .fill(themeManager.currentTheme.black09_white)
//                        .fill(Constants.getRandomColor())
                        
                )
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                )
                .overlay(
                    ellipsisButton
                    , alignment: .topTrailing
                )
                .onReceive(listViewModel.visiblePostIndex2, perform: { value in
                    guard let index, let value else {
                        viewModel.isPausePost2.send(true)
                        return
                    }
                    
                    if index == value {
                        viewModel.isPausePost2.send(false)
                    } else if index <= value + 2 || index >= value - 2{
                        viewModel.isPausePost2.send(true)
                    }
                })
                .onReceive(listViewModel.isMute, perform: { newValue in
                    guard newValue else { return }
                    isMute = newValue
                    UserDefaultsManager.shared.setMuteStatus(newValue)
                })
                .onChange(of: postData.likedByMe, perform: { newValue in
                    if let newValue, newValue {
                        withAnimation(.spring(duration: 0.3, bounce: 0.8, blendDuration: 1)) {
                            viewModel.heartScale = 1.15
                        }
                    } else {
                        viewModel.heartScale = 1.0
                    }
                })
                .onReceive(timer, perform: { _ in
                    withAnimation(.linear) {
                        showLocation.toggle()
                    }
                })
                .onOpenURL { url in
                    guard let host = url.host, host == viewModel.postData?.id ?? "" else { return }
                    
                    switch url.scheme {
                    case "feeling":
                        print("Feeling tapped: \(url.host ?? "")")
                    case "tags":
                        print("Tags tapped")
//                        viewModel.showTagList.toggle()
                        onPressedTag?(viewModel.taggedRef)
                        
                    case "readmore":
                        viewModel.postData?.isExpandedDescription.toggle()
                        postData.isExpandedDescription.toggle()
                        if viewModel.postData?.postType == "post" {
                            viewModel.fullDescription = viewModel.getAttributedDescriptionForPost(content: postData.content ?? "")
                        } else if viewModel.postData?.postType == "review" {
                            viewModel.fullDescription = viewModel.getReviewDescription(content: postData.content ?? "")
                        }

                    default:
                        break
                    }
                }
                .sheet(isPresented: $viewModel.showTagList) {
                    if #available(iOS 16.4, *) {
                        TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.taggedRef), onPressedProfile: { userID in
                            viewModel.showTagList.toggle()
                            onPressedProfile?(userID)
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.7)])
                        .presentationBackground(.clear)
                        .presentationDragIndicator(.hidden)
                        .ignoresSafeArea()
                    } else {
                        TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: viewModel.taggedRef), onPressedProfile: { userID in
                            viewModel.showTagList.toggle()
                            onPressedProfile?(userID)
                        })
                        .environmentObject(themeManager)
                        .presentationDetents([.fraction(0.7)])
                        .ignoresSafeArea()
                    }
                }

            }
        }
    }
}


// MARK: - Components
extension GenericPostView {
    private var profileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            if viewModel.accountType == "business" {
                BusinessProfilePicView(stringURL: viewModel.profilePic ?? "")
                    .offset(y: 4)

            } else {
                IndividualProfilePicView(urlString: viewModel.profilePic ?? "")
                    .offset(y: 4)

            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(viewModel.name ?? "")
                        .font(.custom(Constants.comicFont, size: 16))
                        .lineLimit(1)
                        .foregroundStyle(themeManager.currentTheme.label)
                    
                    // Display collaborators if any
                    if let collaborators = viewModel.postData?.collaboratorRef, !collaborators.isEmpty {
                        Text("&")
                            .font(.custom(Constants.comicFont, size: 16))
                            .foregroundStyle(themeManager.currentTheme.label)
                        
                        ForEach(collaborators.prefix(2)) { collaborator in
                            Text(collaborator.name ?? collaborator.username ?? "")
                                .font(.custom(Constants.comicFont, size: 16))
                                .lineLimit(1)
                                .foregroundStyle(themeManager.currentTheme.label)
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
                    let rating = viewModel.postData?.postedBy?.businessProfileRef?.rating
                    let type = viewModel.postData?.postedBy?.businessProfileRef?.businessTypeRef?.name ?? ""
                    let subType = viewModel.postData?.postedBy?.businessProfileRef?.businessSubtypeRef?.name ?? ""
                    
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                if viewModel.location.isEmpty {
                    Text("\(DateManager.getPostedAgoTime(date: viewModel.postData?.createdAt ?? "", language: localizationManager.language))")
                } else {
                    if showLocation {
                        Text(viewModel.location)
                            .transition(.fade)
                    } else {
                        Text("\(DateManager.getPostedAgoTime(date: viewModel.postData?.createdAt ?? "", language: localizationManager.language))")
                            .transition(.fade)
                    }
                }
                
            }
            .padding(.top, 2)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    private var description: some View {
        VStack {
            Text(viewModel.fullDescription)
                .multilineTextAlignment(.leading)
        }
        .font(.custom(Constants.comicFont, size: 13.2))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white03_darkGray03)
            .frame(height: 1)
    }
    
    
    private var ellipsisButton: some View {
        Circle()
            .fill(themeManager.currentTheme.black09_white)
            .frame(width: 28)
            .overlay(
                Image(systemName: "ellipsis")
                    .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
            )
            .onTapGesture {
                onPressedEllpsis?(viewModel.postData?.id ?? "")
            }
        
            .padding(.top, 8)
            .padding(.trailing, 8)
    }
}


// MARK: - PostCard Components
extension GenericPostView {
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
                if !viewModel.mediaContent.isEmpty {
                    TabView(selection: $viewModel.currentPage) {
                        if !viewModel.mediaContent.isEmpty {
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
                                                viewModel.avplayers[index]?.isMuted = isMute
                                            })
                                            .onAppear {
                                                isMute = UserDefaultsManager.shared.getMuteStatus()
                                                viewModel.avplayers[index]?.isMuted = isMute
                                            }
                                            .onChange(of: isMute) { newValue in
                                                viewModel.avplayers[index]?.isMuted = newValue
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
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onReceive(timer) { _ in
//                        if !viewModel.isPausePost2.value && viewModel.rate == 0 {
//                            viewModel.avplayers[viewModel.currentPage]?.play()
//                        }
                        if !viewModel.isPausePost2.value {
                            viewModel.avplayers[viewModel.currentPage]?.play()
                        }
                    }
                    
//                    .overlay {
//                        ActivityIndicatorView(isVisible: $viewModel.isBufferingVideo, type: .gradient([.white, .white.opacity(0.7), .clear], .round, lineWidth: 2))
//                            .frame(width: Constants.screenWidth * 0.15, height: Constants.screenWidth * 0.15)
//                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
    
    
    private func imageSection(index: Int) -> some View {
        VStack {
            WebImage(url: viewModel.mediaContent[index].url) { image in
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
                        isPaused = true
                        onTapMedia?(index)
                    }
                
            } placeholder: {
                WebImage(url: URL(string: viewModel.postData?.mediaRef?[index].thumbnailURL ?? "")!)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
            }

        }
    }
    
    
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
//                        isPaused = true
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
                CustomVideoPlayer(player: viewModel.avplayers[index]) {
                    
                }
                onRateChange: { rate in
                    guard index == viewModel.currentPage else { return }
                    viewModel.rate = rate
                }
                .onAppear {
                    notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: viewModel.avplayers[index]?.currentItem, queue: .main) { _ in
                        // Reset the video back to the start
                        viewModel.avplayers[index]?.seek(to: .zero)
                        viewModel.avplayers[index]?.play() // Optionally auto-play again
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
//                isPaused = true
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
            
    }
}


// MARK: - ReviewCard Components
extension GenericPostView {
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
}


// MARK: - EventCard Components
extension GenericPostView {
    private var eventContentView: some View {
        
        ZStack {
            WebImage(url: URL(string: viewModel.firstImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(width: Constants.screenWidth - 38)
                    .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
            } placeholder: {
                Image("PostImagePlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
//            Rectangle()
//                .frame(maxWidth: .infinity)
//                .frame(height: Constants.screenHeight * 0.6)
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
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                            
                                        } placeholder: {
                                            Image("PostImagePlaceholder")
                                        }

                                    }
                                    .tag(index)
                                    
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .id(viewModel.mediaContent)
                }
            }
        )
    }
    
    
    private var eventDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.postData?.name ?? "") // This is Event Name
                .font(.custom(Constants.comicBold, size: 14))
            
            
            if let venue = viewModel.postData?.venue, !venue.isEmpty {
                HStack {
                    Image(themeManager.currentTheme.LocationPin4)
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    
                    Text(venue)
                }
            }
            
            HStack {
                Image(themeManager.currentTheme.Clock)
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text(viewModel.dateAndTimeString)
            }
            
            if let interested = viewModel.postData?.interestedPeople {
                if interested == 1 {
                    Text("\(interested) person interested in this event.")
                } else if interested > 1 {
                    Text("\(interested) people interested in this event.")
                }
            }
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var joinButton: some View {
        HStack(spacing: 6) {
            if viewModel.isJoining {
                Image("BlueStar")
                    .resizable()
                    .frame(width: 15, height: 15)
            } else {
                Image(themeManager.currentTheme.BorderStar)
                    .resizable()
                    .frame(width: 15, height: 15)
            }
            
            
            Text(viewModel.isJoining ? "Joined" : "Joining ?")
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
    }
}
