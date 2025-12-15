//
//  BusinessProfileView.swift
//  HotelMedia
//
//  Created by MAC on 20/08/24.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftfulRouting

enum ProfileTab: String {
    case posts
    case photos
    case videos
    case reviews
}

struct UserProfileView: View {
    
    @Binding var createPostOn: Bool
    @StateObject var viewModel: UserProfileViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State var showSheet: Bool = false
    @State var showLocation: Bool = false
    @State private var scale: CGFloat = 1.0 // Current scale
    @State private var lastScale: CGFloat = 1.0 // Last confirmed scale
    
    var onStoryButtonPressed: (() -> Void)?
    
    @GestureState var dragState: DragState = .inactive
    @Namespace var namespace
    @Namespace var profilePicNamespace
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    @AppStorage("newPostCreated") var newPostCreated: Bool = false
    
//    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 6.5),
        GridItem(.flexible(), spacing: 6.5),
        GridItem(.flexible(), spacing: 6.5)
    ]
    
    let amenitiesColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    let singleColumn: [GridItem] = [
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    headerView
                    
                    VStack(spacing: 20) {
                        postAndFollowerDetailSection
                        descriptionSection
                        if !viewModel.userIsIndividual {
                            amenitiesSection
                        }
                        
                        if !viewModel.isOfficial, viewModel.publicProfileID != ownUserID {
                            buttonsSection
                        }
                    }
                    .padding(.bottom, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    
                    ZStack {
//                        if viewModel.userIsIndividual {
//                            threeTabButtonSection
//                        } else {
//                            
//                        }
                        fourTabButtonsSection
                    }
                    .zIndex(2.0)
                    
                    
                    if !viewModel.isPrivateAccount || viewModel.profileData?.isConnected ?? false {
                        if viewModel.currentTab == .photos {
                            photosTab
                                .fullScreenCover(isPresented: $viewModel.showPhotoDetailScreen, content: {
                                    RouterView { _ in
                                        ProfilePhotoDetailView(userProfileID: viewModel.userProfileID, initialMediaID: viewModel.selectedPhotoMediaID, profileData: viewModel.profileData, onPostDeleted: {
                                            postID in
                                            viewModel.removePost(id: postID)
                                        })
                                            .environmentObject(themeManager)
                                            .environmentObject(localizationManager)
                                            .background(BackgroundClearView())
                                    }
                                })
                                .transaction { transaction in
                                    transaction.disablesAnimations = true
                                }
                            
                        } else if viewModel.currentTab == .videos {
                            videosTab
                                .fullScreenCover(isPresented: $viewModel.showVideoDetailScreen, content: {
                                    ProfileVideoDetailView(userProfileID: viewModel.userProfileID, initialMediaID: viewModel.selectedVideoMediaID, profileData: viewModel.profileData)
                                        .environmentObject(themeManager)
                                        .environmentObject(localizationManager)
                                        .background(BackgroundClearView())
                                })
                                .transaction { transaction in
                                    transaction.disablesAnimations = true
                                }
                        } else if viewModel.currentTab == .posts {
                            postsTab
                        } else {
                            reviewsTab
                        }
                    } else {
                        EmptyScreenView(image: "LockIcon2", title: "this_account_is_private".localized(localizationManager.language), subtitle: "follow_this_account_to_see_their_photos_and_videos".localized(localizationManager.language))
                    }
                    
                    if viewModel.currentTab == .photos || viewModel.currentTab == .videos {
                        Rectangle()
                            .fill(themeManager.currentTheme.backgroundColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                    }
                }
                .padding(.horizontal, 16)
                
            }
            .clipped()
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
        .overlay(alignment: .bottom, content: {
            if !viewModel.publicProfileID.isEmpty && !viewModel.userIsIndividual && isIndividual {
                HStack {
                    callButton
                    bookNowButton
                    mapButton
                }
                .padding(.bottom, 28)
            }
        })
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showPostOptionView {
                    themeManager.currentTheme.black05_white05
                        .onTapGesture {
                            viewModel.showPostOptionView.toggle()
                        }
                    VStack(spacing: 6) {
                        if !viewModel.publicProfileID.isEmpty {
                            capsuleButtonView(title: "report".localized(localizationManager.language))
                                .onTapGesture {
                                    viewModel.showPostOptionView.toggle()
                                    viewModel.showReportScreen = true
                                }
                        }
                        
                        if !viewModel.isReviewPost && viewModel.publicProfileID.isEmpty  {
                            capsuleButtonView(title: "edit".localized(localizationManager.language))
                                .onTapGesture {
                                    viewModel.showPostOptionView.toggle()
                                    viewModel.showEditPostScreen()
                                }
                            
                            capsuleButtonView(title: "delete".localized(localizationManager.language))
                                .onTapGesture {
                                    viewModel.showPostOptionView.toggle()
                                    viewModel.showDeletePostModal()
                                }
                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: viewModel.postOptionYOffset - UIApplication.topSafeAreaHeightTHM + 40)
                }
            }
        }
//        .onReceive(timer, perform: { _ in
//            guard !viewModel.publicProfileID.isEmpty else { return }
//            withAnimation(.linear) {
//                showLocation.toggle()
//            }
//        })
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            if viewModel.publicProfileID.isEmpty {
                viewModel.getProfileData()
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack {
                if viewModel.showOptionView {
                    Rectangle()
                        .fill(themeManager.currentTheme.black08_white05)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .onTapGesture {
                            viewModel.showOptionView.toggle()
                        }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack {
                if viewModel.showOptionView {
                    VStack(spacing: 6) {
                        capsuleButtonView(title: viewModel.profileData?.isBlockedByMe ?? false ? "unblock".localized(localizationManager.language) : "block".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.showBlockModal()
                            }
                        capsuleButtonView(title: "share".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.showShareView()
                            }
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showOptionView.toggle()
                                viewModel.reportID = viewModel.publicProfileID
                                viewModel.reportType = "user"
                                viewModel.showReportScreen = true
                            }
                        
//                        if !viewModel.userIsIndividual {
//                            capsuleButtonView(title: "visit".localized(localizationManager.language).capitalized)
//                                .onTapGesture {
//                                    if let lat = viewModel.profileData?.businessProfileRef?.address?.lat,
//                                       let lng = viewModel.profileData?.businessProfileRef?.address?.lng {
//                                        let destination = "\(lat),\(lng)"
//                                        if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
//                                            if UIApplication.shared.canOpenURL(url) {
//                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                                            } else {
//                                                // Fallback to Apple Maps if Google Maps is not installed
//                                                if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
//                                                    UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: 55)
                }
            }
        }
        .overlay {
            ZStack {
                if viewModel.showBigProfilePic {
                    themeManager.currentTheme.black08_white05.ignoresSafeArea()
                        .transition(.fade)
                        .onTapGesture {
                            withAnimation(.bouncy(duration: 0.3)) {
                                viewModel.showBigProfilePic.toggle()
                                scale = 1
                            }
                        }
                    Circle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .overlay {
                            WebImage(url: URL(string: viewModel.userIsIndividual ? viewModel.profileData?.profilePic?.large ?? "" : viewModel.profileData?.businessProfileRef?.profilePic?.large ?? ""), content: { image in
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
                            })
                        }
                        .matchedGeometryEffect(id: "profilePic", in: profilePicNamespace)
                        .frame(width: Constants.screenWidth * 0.7, height: Constants.screenWidth * 0.7)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Update scale during the gesture, clamped between 1 and 5
                                    let newScale = lastScale * value
                                    withAnimation(.linear) {
                                        scale = min(max(newScale, 1), 3)
                                    }
                                }
                                .onEnded { value in
                                    // Save the last scale value when the gesture ends
                                    lastScale = scale
                                }
                        )
                        
                }
                
            }
        }
        .overlay(alignment: .bottom, content: {
            ZStack(alignment: .bottom) {
                if createPostOn {
                    themeManager.currentTheme.black08_white08
                        .onTapGesture {
                            withAnimation(.smooth) {
                                createPostOn = false
                            }
                        }
                }
                VStack {
                    if isIndividual {
                        BlueButton(title: "review".localized(localizationManager.language), icon: "ReviewIcon") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreateReviewScreen()
                        }
                    } else {
                        BlueButton(title: "create_event".localized(localizationManager.language), icon: "CreateEvent") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreateEventScreen()
                        }
                    }
                    
                    HStack {
                        Spacer()
                        BlueButton(title: "create_post".localized(localizationManager.language), icon: "CreatePost") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreatePostScreen()
                        }
                        Spacer()
                        BlueButton(title: "create_story".localized(localizationManager.language), icon: "CreateStory") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            onStoryButtonPressed?()
                        }
                        Spacer()
                        
                    }
                    .offset(y: -16)
                }
                .font(.custom(Constants.comicFont, size: 16))
                .tint(themeManager.currentTheme.label)
                .scaleEffect(createPostOn ? 1 : 0)
                .offset(y: createPostOn ? 0 : 140)
                .animation(.easeInOut(duration: 0.4), value: createPostOn)
                .padding(.bottom, 100)
            }
            
        })
    }
}

// MARK: - Preview

struct BusinessProfileView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        UserProfileView(createPostOn: .constant(false), viewModel: UserProfileViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}

// MARK: - Functions
extension UserProfileView {
    
    func formatNumber(_ number: Double) -> String {
        if number >= 1_000_000_000 {
            
            let remainder = number.truncatingRemainder(dividingBy: 1000_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fB", number / 1_000_000_000) // Billion
            } else {
                return String(format: "%.1fB", number / 1_000_000_000) // Billion
            }
            
        } else if number >= 1_000_000 {
            
            let remainder = number.truncatingRemainder(dividingBy: 1_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fM", number / 1_000_000) // Million
            } else {
                return String(format: "%.1fM", number / 1_000_000) // Million
            }
            
        } else if number >= 1_000 {
            let remainder = number.truncatingRemainder(dividingBy: 1000)
            
            if remainder == 0 {
                return String(format: "%.0fK", number / 1_000) // Thousand
            } else {
                return String(format: "%.1fK", number / 1_000) // Thousand
            }
        } else {
            return String(format: "%.0f", number) // Less than 1,000
        }
    }
}


// MARK: - Components

extension UserProfileView {
    
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
    
    
    private var fourTabButtonsSection: some View {
        HStack(alignment: .top) {
            tabButton(type: .photos)
            tabButton(type: .videos)
            tabButton(type: .posts)
            tabButton(type: .reviews)
        }
        .animation(.bouncy, value: viewModel.currentTab)
        
    }
    
    
    private var threeTabButtonSection: some View {
        HStack(alignment: .top) {
            tabButton(type: .photos)
            tabButton(type: .videos)
            tabButton(type: .posts)
        }
        .animation(.bouncy, value: viewModel.currentTab)
    }
    
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("amenities".localized(localizationManager.language).capitalized)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: (viewModel.profileData?.businessProfileRef?.amenitiesRef?.count ?? 0) + 1 < 5 ? singleColumn : amenitiesColumns, spacing: 4) {
                    
                    WeatherAmenityView()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                    
                    if let isEmpty = viewModel.profileData?.businessProfileRef?.amenitiesRef?.isEmpty {
                        if !isEmpty {
                            ForEach(viewModel.profileData?.businessProfileRef?.amenitiesRef ?? []) { amenity in
                                amenityView(amenity: amenity)
                            }
                        }
                    }
                }
                .frame(height: (viewModel.profileData?.businessProfileRef?.amenitiesRef?.count ?? 0) + 1 < 5 ? 90 : 180)
                .frame(minWidth: Constants.screenWidth - 52, alignment: .center)
                .padding(.horizontal, 10)
            }
        }
    }
    
    
    private var headerView: some View {
        HStack {
            if !viewModel.publicProfileID.isEmpty {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.label)
                    .fontWeight(.bold)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .onTapGesture {
                        viewModel.dismissScreen()
                    }
            }
            
            Text(viewModel.profileData?.username ?? "")
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.publicProfileID.isEmpty {
                settingsButton
            } else if viewModel.publicProfileID != ownUserID {
                if !viewModel.isBlockedByMe && !viewModel.isOfficial {
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
            }
        }
        .padding(.top, 16)
    }
    
    
    private var photosTab: some View {
        LazyVGrid(columns: columns, content: {
            ForEach(viewModel.photosArray) { media in
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width / 3.5)
                    .onTapGesture {
                        if let index = viewModel.photosArray.firstIndex(where: { $0.id == media.id }) {
                            viewModel.openPhotoDetail(at: index)
                        }
                    }
                    .overlay {
                        WebImage(url: URL(string: media.sourceURL ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(height: UIScreen.main.bounds.width / 3.5)
                            .allowsHitTesting(false)
                        
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear{
                        if let lastPhoto = viewModel.photosArray.last {
                            if lastPhoto.id == media.id {
                                viewModel.loadImageData = true
                                viewModel.imageDataPageNo += 1
                                viewModel.getImages()
                            }
                        }
                    }
            }
        })
        .frame(minWidth: UIScreen.main.bounds.width - 32, minHeight: UIScreen.main.bounds.height * 0.4, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            VStack {
                if viewModel.photosArray.isEmpty && !viewModel.loadingImageData  {
                    EmptyScreenView(image: "PhotoIcon2", title: "no_photos_uploaded_yet".localized(localizationManager.language))
                } else if viewModel.photosArray.isEmpty && viewModel.loadingImageData {
                    CustomProgressView(showIndicator: .constant(true))
                }
                
            }
        }
    }
    
    
    private var paginationView: some View {
        Rectangle()
            .fill(.black.opacity(0.001))
            .frame(maxWidth: .infinity)
            .frame(height: 20)
    }
    
    
    private var videosTab: some View {
        LazyVGrid(columns: columns, content: {
            ForEach(viewModel.videosArray) { media in
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width / 3.5)
                    .overlay {
                        ZStack {
                            if let url = media.thumbnailURL {
                                WebImage(url: URL(string: url))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: UIScreen.main.bounds.width / 3.5)
                            }
                            
                            if let views = media.views {
                                HStack(spacing: 4) {
                                    Image("eye2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                    Text(formatNumber(Double(views)))
                                        .withComicFont(9, color: .white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                .padding(8)
                                
                            }
                            
                            Image("PlayIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .onTapGesture {
                                    print("Video Tapped...")
                                    viewModel.selectedVideoMediaID = media.id
                                    viewModel.showVideoDetailScreen.toggle()
                                }
                        }
                        
                    }
                    .onAppear{
                        if let lastVideo = viewModel.videosArray.last {
                            if lastVideo.id == media.id {
                                viewModel.loadVideoData = true
                                viewModel.videoDataPageNo += 1
                                viewModel.getVideos()
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        })
        .frame(minWidth: UIScreen.main.bounds.width - 32, minHeight: UIScreen.main.bounds.height * 0.4, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            ZStack {
                if viewModel.videosArray.isEmpty && !viewModel.loadingVideoData {
                    EmptyScreenView(image: "VideosIcon", title: "no_video_uploaded_yet".localized(localizationManager.language))
                }
                if viewModel.loadingVideoData && viewModel.videosArray.isEmpty {
                    CustomProgressView(showIndicator: .constant(true))
                }
                
            }
        }
        .onAppear {
            viewModel.getVideos()
        }

    }
    
    
    private var reviewsTab: some View {
        VStack {
            PostView(belongTo: .profile, posts: $viewModel.totalReviewData, viewModel: PostViewModel(router: viewModel.router), onPagination: {
                viewModel.loadReviewData = true
                viewModel.reviewDataPageNo += 1
                viewModel.getReviewsData()
                
            }, onPressedProfile: { profileID in
//                if ownUserID != profileID {
//                    viewModel.showUserProfileScreen(id: profileID)
//                }
            }, onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.selectedPostID = postID
                viewModel.isReviewPost = true
                
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
        }
        .frame(minWidth: UIScreen.main.bounds.width - 32, minHeight: UIScreen.main.bounds.height * 0.4, alignment: .top)
        .overlay {
            ZStack {
                if viewModel.totalReviewData.isEmpty && !viewModel.loadingReviewData  { 
                    EmptyScreenView(image: "ReviewsIcon", title: "no_reviews_yet".localized(localizationManager.language))
                }
                if viewModel.loadingReviewData && viewModel.reviewsArray.isEmpty {
                    CustomProgressView(showIndicator: .constant(true))
                }
                
            }
        }
        .onAppear {
            viewModel.getReviewsData()
        }
    }
    
    
    private var postsTab: some View {
        VStack {
            PostView(belongTo: .profile, posts: $viewModel.totalPostData, viewModel: PostViewModel(router: viewModel.router), showDeleteButton: true, onPagination: {
                viewModel.loadPostData = true
                viewModel.postDataPageNo += 1
                viewModel.getPostData()
                
            }, onPressedProfile: { profileID in
//                if ownUserID != profileID {
//                    viewModel.showUserProfileScreen(id: profileID)
//                }
            }, onPressedEvent: { eventID in
//                viewModel.showEventDetailScreen(id: eventID)
                
            }, onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.selectedPostID = postID
                viewModel.isReviewPost = false
                
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
            
        }
        .frame(minWidth: UIScreen.main.bounds.width - 32, minHeight: UIScreen.main.bounds.height * 0.4, alignment: .top)
        .overlay {
            ZStack {
                if viewModel.totalPostData.isEmpty && !viewModel.loadingPostData {
                    EmptyScreenView(image: "PostsIcon", title: "no_post_uploaded_yet".localized(localizationManager.language))
                }
                if viewModel.loadingPostData && viewModel.totalPostData.isEmpty {
                    CustomProgressView(showIndicator: .constant(true))
                }
            }
        }
        .onAppear {
            viewModel.getPostData()
        }
    }
    
    
    private func tabButton(type: ProfileTab) -> some View {
        VStack {
            HStack(spacing: 5) {
                Image(type.rawValue.capitalized + "Icon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.currentTab == type ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white06_darkGray06)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(type.rawValue.localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(viewModel.currentTab == type ? themeManager.currentTheme.white_darkGray : themeManager.currentTheme.white06_darkGray06)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                viewModel.currentTab = type
            }
            
            if type == viewModel.currentTab {
                RoundedRectangle(cornerRadius: 1)
                    .fill(themeManager.currentTheme.label)
                    .matchedGeometryEffect(id: "tabLine", in: namespace)
                    .frame(height: 2)
            }
        }
    }
    
    
    private var postAndFollowerDetailSection: some View {
        HStack(spacing: 0) {
            VStack {
                if viewModel.publicProfileID.isEmpty {
                    selfProfilePicView
                } else {
                    if viewModel.userIsIndividual {
                        individaulProfilePic
                    } else {
                        businessProfilePic
                    }
                }
            }
            .matchedGeometryEffect(id: "profilePic", in: profilePicNamespace)
            .opacity(viewModel.showBigProfilePic ? 0.0 : 1.0)
            .onTapGesture {
                viewModel.showProfileStoryOrFallback {
                    withAnimation(.bouncy(duration: 0.3)) {
                        viewModel.showBigProfilePic = true
                        scale = 1
                    }
                }
            }
            .onLongPressGesture {
                withAnimation(.bouncy(duration: 0.3)) {
                    viewModel.showBigProfilePic = true
                    scale = 1
                }
            }
            
            
            
            
            Spacer(minLength: 0)
            Spacer(minLength: 0)
            
            infoView(title: "posts".localized(localizationManager.language), value: "\(viewModel.profileData?.posts ?? 0)")
//                .onTapGesture {
//                    viewModel.showBookTableScreen()
//                }
            Spacer(minLength: 0)
            divider
            Spacer(minLength: 0)
            infoView(title: "followers".localized(localizationManager.language), value: "\(viewModel.profileData?.follower ?? 0)")
                .onTapGesture {
                    if !viewModel.isOfficial {
                        viewModel.showFollowersListScreen(show: "followers")
                    }
                }
            Spacer(minLength: 0)
            divider
            Spacer(minLength: 0)
            infoView(title: "following".localized(localizationManager.language), value: "\(viewModel.profileData?.following ?? 0)")
                .onTapGesture {
                    if !viewModel.isOfficial {
                        viewModel.showFollowersListScreen(show: "following")
                    }
                }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
    
    
    private var selfProfilePicView: some View {
        
        VStack {
            if let profileCompleted = viewModel.profileData?.profileCompleted {
                if profileCompleted == 100 {
                    Circle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(width: 56, height: 56)
                        .overlay {
                            WebImage(url: URL(string: viewModel.userIsIndividual ? viewModel.profileData?.profilePic?.small ?? "" : viewModel.profileData?.businessProfileRef?.profilePic?.small ?? ""), content: { image in
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
                        }
                } else {
                    Circle()
                        .stroke(lineWidth: 2)
                        .fill(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .overlay(
                            ProfileProgressCircle(progress: .constant(profileCompleted))
                                .stroke(lineWidth: 2)
                                .fill(.green)
                                .rotationEffect(Angle(degrees: 270))
                                .rotation3DEffect(
                                    Angle(degrees: 180),
                                                          axis: (x: 0.0, y: 1.0, z: 0.0)
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle()
                                        .fill(themeManager.currentTheme.darkGray06_darkGray008)
                                        .frame(width: 54, height: 54)
                                )
                                .overlay(
                                    WebImage(
                                        url: URL( string: viewModel.userIsIndividual ? viewModel.profileData?.profilePic?.small ?? "" : viewModel.profileData?.businessProfileRef?.profilePic?.small ?? "" )
                                    )
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 52, height: 52)
                                        .clipShape(Circle())
                                )
                        )
                }
               
            }
        }
    }
    
    
    private var businessProfilePic: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 56, height: 56)
            .overlay {
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 52, height: 52)
            }
            .overlay {
                WebImage(url: URL(string: viewModel.userProfilePic), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                })
            }
    }
    
    
    private var individaulProfilePic: some View {
        Circle()
            .fill(.hmDarkestGray.opacity(0.5))
            .frame(width: 56, height: 56)
            .overlay {
                WebImage(url: URL(string: viewModel.userProfilePic), content: { image in
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
            }
            
    }
    
    
    private var buttonsSection: some View {
        HStack {
            // Edit Profile Button
            if viewModel.publicProfileID.isEmpty {
                capsuleButton(image: "EditProfile", title: "edit_profile".localized(localizationManager.language)) {
                    // action
                    if let profileData = viewModel.profileData {
                        viewModel.showEditProfileScreen(profileData: profileData)
                    }
                }
                
                // Share Profile Button
                capsuleButton(image: "PaperPlane", title: "share_profile".localized(localizationManager.language)) {
                    viewModel.showShareView()
                }
                
            } else {
                if let isConnected = viewModel.profileData?.isConnected,
                   let isRequested = viewModel.profileData?.isRequested,
                   let isBlockByMe = viewModel.profileData?.isBlockedByMe {
                    
                    if isBlockByMe { // Blocked by me
                        followButton(image: "AddPerson2", title: "unblock".localized(localizationManager.language).capitalized, buttonColor: themeManager.currentTheme.darkGray05_hmIndigo, borderColor: .white.opacity(0.5))
                            .onTapGesture {
                                viewModel.showUnblockModal()
                            }
                        
                    } else if !isConnected && !isRequested { // When not following the user.
                        followButton(image: "AddPerson2", title: "follow".localized(localizationManager.language).capitalized, buttonColor: themeManager.currentTheme.darkGray05_hmIndigo, borderColor: .white.opacity(0.5))
                            .onTapGesture {
                                if viewModel.followButtonEnabled {
                                    viewModel.followUser()
                                }
                            }
                    } else if isRequested && !isConnected { // When requested the user.
                        followButton(image: "PersonMinus", title: "requested".localized(localizationManager.language).capitalized, buttonColor: themeManager.currentTheme.darkGray05_hmIndigo, borderColor: .white.opacity(0.5))
                            .onTapGesture {
                                viewModel.profileData?.isConnected = false
                                viewModel.profileData?.isRequested = false
                                viewModel.followButtonEnabled = true
                                viewModel.unfollowUser()
                            }
                        
                    } else { // When following the user.
                        followButton(image: "PersonMinus", title: "unfollow".localized(localizationManager.language).capitalized, buttonColor: themeManager.currentTheme.hmIndigo05_darkGray05, borderColor: themeManager.currentTheme.hmIndigo_white05)
                            .onTapGesture {
                                if viewModel.followButtonEnabled {
                                    viewModel.unfollowUser()
                                }
                            }
                    }
                    
                }
                
                // Share Profile Button
                if !viewModel.isBlockedByMe {
                    capsuleButton(image: "MessageIcon3", title: "message".localized(localizationManager.language).capitalized) {
                        // action
                        viewModel.showChatScreen()
                    }
                }
                
                
                if !viewModel.userIsIndividual && !viewModel.isBlockedByMe {
                    capsuleButton(image: "BookIcon", title: "visit".localized(localizationManager.language).capitalized) {
                        // action
                        if let websiteURL = URL(string: viewModel.profileData?.businessProfileRef?.website ?? ""), UIApplication.shared.canOpenURL(websiteURL) {
                            viewModel.redirectedToWebsite(id: viewModel.profileData?.businessProfileID ?? "")
                            UIApplication.shared.open(websiteURL)
                        }
                    }
                }
                
//                if viewModel.userIsIndividual || viewModel.isBlockedByMe {
//                    capsuleButton(image: "PaperPlane", title: "share_profile".localized(localizationManager.language)) {
//                        viewModel.showShareView()
//                    }
//                }
            }
            
        }
        .padding(.horizontal, 16)
//        .padding(.bottom, 16)
        .sheet(isPresented: $viewModel.isSharePresented) {
            UnifiedShareSheet(
                shareURL: viewModel.shareURL.absoluteString,
                postData: nil,
                router: viewModel.router,
                onChatSelected: { username, userID, profilePic, name in
                    viewModel.isSharePresented = false
                },
                onDismiss: {
                    viewModel.isSharePresented = false
                }
            )
            .environmentObject(ThemeManager.shared)
            .environmentObject(LocalizationManager.shared)
                .presentationDetents([.medium, .large])
        }
    }
    
    
    private var descriptionSection: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.userIsIndividual {
                        Text(viewModel.profileData?.name ?? "")
                            .font(.custom(Constants.comicFont, size: 16))
                            .foregroundColor(themeManager.currentTheme.label)
                    } else {
                        Text(viewModel.profileData?.businessProfileRef?.name ?? "")
                            .font(.custom(Constants.comicFont, size: 16))
                            .foregroundColor(themeManager.currentTheme.label)
                    }
                    
                    
                    if !viewModel.userIsIndividual {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 2) {
                                Text(viewModel.profileData?.businessProfileRef?.businessTypeRef?.name ?? "")
                                WebImage(url: URL(string: viewModel.profileData?.businessProfileRef?.businessTypeRef?.icon ?? ""))
                                    .resizable()
                                    .renderingMode(.template)
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                
                                
                                if let rating = viewModel.profileData?.businessProfileRef?.rating {
                                    if rating > 0 {
                                        HStack(spacing: 2) {
                                            Text("-")
                                                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                                            Image("RatingStar")
                                                .renderingMode(.template)
                                                .foregroundColor(rating.getStarColor())
                                                .frame(height: 12)
                                            
                                            Text("\(String(format: "%.1f", rating))")
                                        }
                                        .font(.custom(Constants.comicFont, size: 12))
                                        .foregroundColor(rating.getStarColor())
                                    }
                                }
                            }
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
//                            .opacity(showLocation ? 0.0 : 1.0)
                            
                            Text(viewModel.toShowLocationString)
                                .font(.custom(Constants.comicFont, size: 12))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
//                                    .opacity(showLocation ? 1.0 : 0.0)
                        }
                    }
                }
                
                Spacer()
                
                if viewModel.publicProfileID.isEmpty {
                    if let percentage = viewModel.profileData?.profileCompleted, percentage != 100 {
                        profileCompletePercentageView
                            .onTapGesture {
                                if let profileData = viewModel.profileData {
                                    viewModel.showEditProfileScreen(profileData: profileData)
                                }
                            }
                    }
                } else if !viewModel.publicProfileID.isEmpty && !viewModel.userIsIndividual && isIndividual {
                    capsuleButton(image: "BorderStar2", title: "write_a_review".localized(localizationManager.language)) {
                        viewModel.getReviewProfile(placeID: viewModel.profileData?.businessProfileRef?.placeID ?? "", businessProfileID: viewModel.profileData?.businessProfileID ?? "")
                    }
                    .frame(width: 122)
                }
            }
            
            if viewModel.userIsIndividual {
                if let bio = viewModel.profileData?.bio, !bio.isEmpty {
                    HStack(alignment: .top){
                        Circle()
                            .fill(themeManager.currentTheme.white06_darkGray06)
                            .offset(y: 8)
                            .frame(width: 3)
                        Text(bio)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    }
                }
            } else {
                if let bio = viewModel.profileData?.businessProfileRef?.bio, !bio.isEmpty {
                    HStack(alignment: .top){
                        Circle()
                            .fill(themeManager.currentTheme.white06_darkGray06)
                            .offset(y: 8)
                            .frame(width: 3)
                        Text(bio)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    }
                }
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    
    private func infoView(title: String, value: String) -> some View{
        VStack(spacing: 5) {
            Text(value)
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(themeManager.currentTheme.label)
            Text(title)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        }
        .padding(.horizontal, 16)
    }
    
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white06_darkGray06)
            .frame(width: 0.75)
            
    }
    
    
    private var ellipsisButton: some View {
        ZStack {
            Circle()
                .fill(.hmIndigo.opacity(0.2))
                .frame(width: 32)
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 4)
                }
            }
        }
        .onTapGesture {
        }
    }
    
    
    private var profileCompletePercentageView: some View {
        ZStack {
            Capsule()
                .fill(
                    themeManager.currentTheme.hmgreen_hmgreen06
//                    .shadow(.inner(color: .black, radius: 7))
//                    .shadow(.inner(color: .black, radius: 5))
//                    .shadow(.inner(color: .black.opacity(0.5), radius: 3))
                )
                .frame(width: 112, height: 28)
                .overlay(
                    Text(String(format: "%.1f", arguments: [viewModel.profileData?.profileCompleted ?? 0]) + "% " + "completed".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 11))
                        .foregroundColor(.white)
                        
                )
        }
    }
    
    
    private var settingsButton: some View {
        Button(action: {
            viewModel.showSettingScreen()
        }) {
            Image(themeManager.currentTheme.SettingIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
    }
    
    
    private func capsuleButton(image: String, title: String, completion: @escaping () -> Void) -> some View {
        Button(action: {
            completion()
        }, label: {
            HStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_hmwhite08)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Text(title)
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.white06_hmwhite08)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(CapsuleBackground(height: 32, borderWidth: 1.2, borderColor: .white.opacity(0.5), backgroundColor: themeManager.currentTheme.darkGray05_hmIndigo))
        })
    }
    
    
    private func followButton(image: String, title: String, buttonColor: Color, borderColor: Color) -> some View {
        HStack(spacing: 4) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.white06_hmwhite08)
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text(title)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white06_hmwhite08)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(CapsuleBackground(height: 32, borderWidth: 1.2, borderColor: borderColor, backgroundColor: buttonColor))
    }
    
    
    private func amenityView(amenity: Ref) -> some View {
        VStack {
            Circle()
                .stroke(lineWidth: 1.2)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 50, height: 50)
                .overlay(
                    WebImage(url: URL(string: amenity.icon ?? ""))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                )
            
            Text(amenity.name ?? "")
                .font(.custom(Constants.comicFont, size: 11))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .padding(.horizontal, 8)
        }
        .padding(.top, 2)
        .frame(width: (Constants.screenWidth - 52)/4, height: 90, alignment: .top)
        
    }
    
    
    private func amenityView2(icon: String, title: String) -> some View {
        VStack {
            Circle()
                .stroke(lineWidth: 1.2)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 50, height: 50)
                .overlay(
                    WebImage(url: URL(string: icon))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                )
            
            Text(title)
                .font(.custom(Constants.comicFont, size: 11))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .padding(.horizontal, 8)
        }
        .padding(.top, 2)
        .frame(width: (Constants.screenWidth - 52)/4, height: 90, alignment: .top)
        
    }
    
    
    private var saveButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
            Circle()
                .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                .frame(width: 42, height: 42)
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
                .frame(width: 42, height: 42)
        }
        .overlay {
            Image(viewModel.savedByMe ? themeManager.currentTheme.bookmarkfill : "bookmark")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
                .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
    //            .animation(.none, value: viewModel.savedByMe)
        }
        .onTapGesture {
            viewModel.savedByMe.toggle()
        }
       
    }
    
    private var mapButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
            Circle()
                .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                .frame(width: 42, height: 42)
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
                .frame(width: 42, height: 42)
        }
        .overlay {
            Image("Map4")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
    //            .animation(.none, value: viewModel.savedByMe)
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
        .onTapGesture {
            onTapMapButton()
//            openGoogleMaps()
        }
        .confirmationDialog("Open with", isPresented: $viewModel.showMapOptions) {
            Button("Google Maps") {
                openGoogleMaps()
            }
            Button("Apple Maps") {
                openAppleMaps()
            }
        }
    }
    
    private var callButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
            Circle()
                .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                .frame(width: 42, height: 42)
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
                .frame(width: 42, height: 42)
        }
        .overlay {
            Image("Call")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
    //            .animation(.none, value: viewModel.savedByMe)
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
        .onTapGesture {
            if let dialCode = viewModel.profileData?.businessProfileRef?.dialCode,
               let phoneNumber = viewModel.profileData?.businessProfileRef?.phoneNumber,
               let url = URL(string: "tel://\(dialCode.replacingOccurrences(of: "+", with: ""))\(phoneNumber)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    
    private var bookNowButton: some View {
        let booking = viewModel.profileData?.booking ?? ""
        return HStack {
            Image("BookIcon")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 21))
                .foregroundColor(.white)
                .scaledToFit()
                .frame(width: 21, height: 21)
            
            if booking == "booking" {
                Text("Book now".localized(localizationManager.language))
                    .withComicFont(14, color: .white)
                
            } else if booking == "book-table" {
                Text("Book Table".localized(localizationManager.language))
                    .withComicFont(14, color: .white)
                
            } else if booking == "book-banquet" {
                Text("Book Banquet".localized(localizationManager.language))
                    .withComicFont(14, color: .white)
                
            } else {
                Text("Book now".localized(localizationManager.language))
                    .withComicFont(14, color: .white)
            }
            
            
        }
        .padding(.vertical, 10.5)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.6))
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 3)
        .onTapGesture {
            if booking == "booking" {
                viewModel.showBookingInfoScreen()
                
            } else if booking == "book-table" {
                viewModel.showBookTableScreen()
                
            } else if booking == "book-banquet" {
                viewModel.showBookBanquetScreen()
                
            } else {
                viewModel.showBookingInfoScreen()
            }
            
        }
    }
}
// MARK: - Functions
extension UserProfileView {
    
    func onTapMapButton() {
        if let lat = viewModel.profileData?.businessProfileRef?.address?.lat,
           let lng = viewModel.profileData?.businessProfileRef?.address?.lng {
            let destination = "\(lat),\(lng)"
            if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
                if UIApplication.shared.canOpenURL(url) {
                    viewModel.showMapOptions.toggle()
//                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback to Apple Maps if Google Maps is not installed
                    if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
                        UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    
    func openGoogleMaps() {
        if let lat = viewModel.profileData?.businessProfileRef?.address?.lat,
           let lng = viewModel.profileData?.businessProfileRef?.address?.lng {
            let destination = "\(lat),\(lng)"
            if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    
    func openAppleMaps() {
        if let lat = viewModel.profileData?.businessProfileRef?.address?.lat,
           let lng = viewModel.profileData?.businessProfileRef?.address?.lng {
            let destination = "\(lat),\(lng)"
            if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
                UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
            }
        }
    }
}


// MARK: -  WeatherAmenityView
struct WeatherAmenityView: View {
    
    @State var title: String = ""
    @State var icon: String = ""
    
    @EnvironmentObject var viewModel: UserProfileViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Circle()
                .stroke(lineWidth: 1.2)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(icon)
                        .renderingMode(icon == "AQI" ? .template : .original)
                        .resizable()
                        .foregroundColor(themeManager.currentTheme.label)
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                )
            
            Text(title)
                .font(.custom(Constants.comicFont, size: 11))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .padding(.horizontal, 8)
        }
        .padding(.top, 2)
        .frame(width: (Constants.screenWidth - 52)/4, height: 90, alignment: .top)
        .onReceive(viewModel.weatherIcon) { icon in
            withAnimation(.linear) {
                self.icon = icon ?? ""
            }
        }
        .onReceive(viewModel.weatherTitle) { title in
            withAnimation(.linear) {
                self.title = title ?? ""
            }
        }
    }
}
