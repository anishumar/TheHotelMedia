//
//  PostCardView.swift
//  HotelMedia
//
//  Created by MAC on 31/07/24.
//

import SwiftUI
import SDWebImageSwiftUI
import AVKit

enum MediaType: Hashable {
    case image(urlString: String)
    case video(urlString: String)
    
    var url: URL {
        switch self {
        case .image(let urlString):
            if let url = URL(string: urlString) {
                return url
            }
        case .video(let urlString):
            if let url = URL(string: urlString) {
                return url
            }
        }
        
        return URL(string: "https://www.google.com")!
    }
    
    var isImage: Bool {
        switch self {
        case .image:
            return true
        case .video:
            return false
        }
    }
}

struct PostCardView: View {
    
    @Binding var isPaused: Bool
    @Binding var postData: PostData
    @StateObject var viewModel: PostCardViewModel
    var postIndex: Int? = nil
    var onPressedComment: ((String) -> Void)? = nil
    var onPressedShare: ((String, String) -> Void)? = nil
    var onPressedEllpsis: ((String) -> Void)? = nil
    var onPressedLike: ((Bool, Int) -> Void)? = nil
    var onPressedBookmark: ((Bool) -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    var onPaused: (() -> Void)?
    var onAddingComment: ((Int) -> Void)? = nil
    var onPressedUrl: ((URL) -> Void)? = nil
    var onTapMedia: ((Int) -> Void)? = nil
    @State private var notificationObserver: Any?
    @State private var notificationObserver2: Any?
    @State private var readyToPlay: Bool = false
    @State private var isExpanded: Bool = false
    @State private var showLocation: Bool = true
    @State var skip: Bool = true
    @State var uiImage: UIImage? = nil
    
    @AppStorage("isMute") var isMute: Bool = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.displayScale) var displayscale
    
    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            profileDetailView
                .padding(.bottom, 4)
                .onTapGesture {
                    if let id = viewModel.data.postedBy?.id {
                        onPressedProfile?(id)
                    }
                }
//                .overlay {
//                    Rectangle()
//                        .fill(.black.opacity(0.001))
//                        .onTapGesture {
//                            if let id = viewModel.data.postedBy?.id {
//                                onPressedProfile?(id)
//                            }
//                        }
//                }
            
            VStack {
                if !viewModel.mediaContent.isEmpty {
                    contentView
                }
            }
            
//
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
            
            ZStack {
                if !viewModel.content.isEmpty || !viewModel.feeling.isEmpty || !viewModel.taggedRef.isEmpty || !viewModel.location.isEmpty {
                    description
                        .offset(y: viewModel.mediaContent.isEmpty ? -6 : 0)
                }
            }
            
            divider
            ZStack {
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
                        onPressedLike?(viewModel.likedByMe, viewModel.likesCount)
                    }
                    
                    HMCustomButton(icon: .constant(themeManager.currentTheme.comment), count: $viewModel.comments)
                        .onTapGesture {
                            haptics(.light)
                            onPressedComment?(viewModel.data.id ?? "")
                        }
                    HMCustomButton(icon: .constant(themeManager.currentTheme.share), count: $viewModel.shares)
                        .onTapGesture {
                            haptics(.light)
                            onPressedShare?(viewModel.data.id ?? "", viewModel.data.postedBy?.name ?? "")
                        }
                    
                    if let views = viewModel.data.views, views > 0 {
                        HMCustomButton(icon: .constant(themeManager.currentTheme.eye3), count: .constant(Double(views).formatNumber()))
                    }
                    
                    Spacer()
                    Button(action: {
                        haptics(.light)
                        viewModel.savedByMe.toggle()
                        onPressedBookmark?(viewModel.savedByMe)
                    }) {
                        Image(viewModel.savedByMe ? "bookmarkfill" : themeManager.currentTheme.bookmark)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
                            .animation(.none, value: viewModel.savedByMe)
                    }
                }
                .padding(.vertical, 2)
            }
//            .zIndex(2.0)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(
            CustomShape4()
                .fill(themeManager.currentTheme.black09_white)
                
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
//        .animation(.easeInOut(duration: 0.2 ), value: viewModel.currentPage)
        .onChange(of: isPaused, perform: { value in
            viewModel.isPausePost = isPaused
        })
        .onChange(of: postData, perform: { newValue in
            viewModel.data = newValue
        })
        .onReceive(viewModel.$likedByMe, perform: { newValue in
            if newValue {
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
//        .onReceive(NotificationCenter.default.publisher(for: .readmore), perform: { notification in
//            if let id = notification.userInfo?["id"] as? String, id == postData.id {
//                viewModel.data.isExpandedDescription.toggle()
//                viewModel.fullDescription = viewModel.getAttributedDescription(content: viewModel.content)
//                if !viewModel.avplayers.isEmpty {
//                    viewModel.avplayers[viewModel.currentPage]?.play()
//                }
//            }
//        })
//        .onReceive(NotificationCenter.default.publisher(for: .tags), perform: { notification in
//            if let id = notification.userInfo?["id"] as? String, id == postData.id {
//                viewModel.showTagList.toggle()
//            }
//        })
        .onOpenURL { url in
            guard let host = url.host, host == viewModel.data.id ?? "" else { return }
            
            switch url.scheme {
            case "feeling":
                print("Feeling tapped: \(url.host ?? "")")
            case "tags":
                print("Tags tapped")
                viewModel.showTagList.toggle()
                
            case "readmore":
//                guard let host = url.host, host == viewModel.data.id ?? "" else { return }
                viewModel.data.isExpandedDescription.toggle()
                viewModel.fullDescription = viewModel.getAttributedDescription(content: viewModel.content)
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

// MARK: - Preview
#Preview {
    ScrollView(.vertical) {
        VStack {
            PostCardView(isPaused: .constant(true), postData: .constant(DummyData.post), viewModel: PostCardViewModel(data: DummyData.post))
        }
        .padding(.horizontal, 16)
    }
    .background(Color.black)
    
    
}



// MARK: - Components
extension PostCardView {
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white03_darkGray03)
            .frame(height: 1)
    }
    
    
//    private var description: some View {
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
//    }
    
    private var description: some View {
        VStack {
            Text(viewModel.fullDescription)
                .multilineTextAlignment(.leading)
        }
        .font(.custom(Constants.comicFont, size: 13.2))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    
    private var contentView: some View {
        
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
                            ForEach(0..<viewModel.mediaContent.count) { index in

                                VStack {
                                    if viewModel.mediaContent[index].isImage {
                                        imageSection(index: index)
//                                            .tag(index)
                                    } else {
                                        videoSection(index: index)
//                                            .tag(index)
                                    }
                                }
                                .tag(index)
                                
                            }
                        }
                    }
                    .onChange(of: isMute, perform: { value in
                        viewModel.avplayers[viewModel.currentPage]?.isMuted = value
                    })
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .id(viewModel.mediaContent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
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
//                        viewModel.showMediaPreview.toggle()
                        onTapMedia?(index)
                    }
                
            } placeholder: {
                WebImage(url: URL(string: viewModel.data.mediaRef?[index].thumbnailURL ?? "")!)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
            }

        }
    }
    
    
    private func videoSection(index: Int) -> some View {
        Rectangle()
            .fill(themeManager.currentTheme.backgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                CustomVideoPlayer(player: viewModel.avplayers[index], onReadyToPlay: {
                    if !viewModel.isPausePost {
                        viewModel.avplayers[index]?.play()
                    }
                }, onRateChange: { rate in
                    
                })
                .onChange(of: isPaused, perform: { value in
                    if value {
                        viewModel.avplayers[index]?.pause()
                        if let observer = notificationObserver {
                            NotificationCenter.default.removeObserver(observer)
                            notificationObserver = nil // Clear the observer after removal
                        }
                    } else {
                        // Add observer for video end
                        viewModel.avplayers[index]?.play()
                        notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: viewModel.avplayers[index]?.currentItem, queue: .main) { _ in
                            // Reset the video back to the start
                            viewModel.avplayers[index]?.seek(to: .zero)
                            viewModel.avplayers[index]?.play() // Optionally auto-play again
                        }
                    }
                })
                .onAppear {
                    viewModel.avplayers[index]?.isMuted = isMute
                    notificationObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: viewModel.avplayers[index]?.currentItem, queue: .main) { _ in
                        // Reset the video back to the start
                        viewModel.avplayers[index]?.seek(to: .zero)
                        viewModel.avplayers[index]?.play() // Optionally auto-play again
                    }
                    // Add observer for video end
                }
                .onDisappear {
                    viewModel.avplayers[index]?.pause()
                    viewModel.previousPage = 0
                    if let observer = notificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                        notificationObserver = nil // Clear the observer after removal
                    }
                }
                //                    .tag(index)
                .allowsHitTesting(false)
            }
            .overlay {
                WebImage(url: URL(string: viewModel.data.mediaRef?[index].thumbnailURL ?? "")!)
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
                        .onTapGesture {
                            isMute.toggle()
                            if !isMute {
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
                .offset(x: -12, y: -12)
                
            })
            .onTapGesture {
                isPaused = true
                onTapMedia?(index)
//                viewModel.showMediaPreview.toggle()
            }
    }
    
    
    private var ellipsisButton: some View {
        Button(action: {
            onPressedEllpsis?(viewModel.data.id ?? "")
        }, label: {
            Circle()
                .fill(themeManager.currentTheme.black09_white)
                .frame(width: 28)
                .overlay(
                    Image(systemName: "ellipsis")
                        .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
                )
        })
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
    
    
    private var profileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            if viewModel.accountType == "business" {
                BusinessProfilePicView(stringURL: viewModel.profilePic ?? "")
//                businessProfilePicView
                    .offset(y: 4)

            } else {
                IndividualProfilePicView(urlString: viewModel.profilePic ?? "")
//                individualProfilePicView
                    .offset(y: 4)

            }
//            Image("Logo")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 46, height: 46)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.label)
                    .padding(.trailing, 40)
                
                if viewModel.accountType == "business" {
//                    ratingView
                    let rating = viewModel.data.postedBy?.businessProfileRef?.rating
                    let type = viewModel.data.postedBy?.businessProfileRef?.businessTypeRef?.name ?? ""
                    let subType = viewModel.data.postedBy?.businessProfileRef?.businessSubtypeRef?.name ?? ""
                    
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                if viewModel.location.isEmpty {
                    Text("\(DateManager.getPostedAgoTime(date: viewModel.data.createdAt ?? "", language: localizationManager.language))")
                } else {
                    if showLocation {
                        Text(viewModel.location)
                            .transition(.fade)
                    } else {
                        Text("\(DateManager.getPostedAgoTime(date: viewModel.data.createdAt ?? "", language: localizationManager.language))")
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
    
    
    private var businessProfilePicView: some View {
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
                        .frame(width: 40, height: 40)
                        .allowsHitTesting(false)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .allowsHitTesting(false)
                })
            )
    }
    
    
    private var individualProfilePicView: some View {
        Circle()
            .fill(.black)
            .frame(width: 46, height: 46)
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                })
            )
    }
}
