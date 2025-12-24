//
//  MainTabBarView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import Lottie

enum TabbedItem {
    case home
    case search
    case chat
    case profile
    case insight
    
    var title: String{
        switch self {
        case .home:
            return "Home"
        case .search:
            return "Search"
        case .chat:
            return "Chat"
        case .profile:
            return "Profile"
        case .insight:
            return "Insight"
        }
    }
    
    var iconName: String{
        switch self {
        case .home:
            return "home"
        case .search:
            return "search"
        case .chat:
            return "chat"
        case .profile:
            return "profile"
        case .insight:
            return "insight"
        }
    }
}

struct MainTabBarView: View {
    
    @StateObject var viewModel: MainTabBarViewModel
    @StateObject var compassHeading = CompassHeading()
    @StateObject var gyroManager = GyroManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @GestureState var dragState: DragState = .inactive
    
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("firstTimeAfterLogin") var firstTimeAfterLogin: Bool = true
    @AppStorage("ownUserID") var ownUserID: String = ""
    @AppStorage("launchViaNotification") var launchViaNotification: Bool = false
    @AppStorage("viaMessage") var viaMessage: Bool = false
    @AppStorage("viaOtherNotification") var viaOtherNotification: Bool = false
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("clearChat") var clearChat: Bool = true
    
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabViewContent
            
//            Color.black.opacity(viewModel.createPostOn ? 0.8 : 0)
//                .onTapGesture {
//                    withAnimation(.smooth) {
//                        viewModel.createPostOn = false
//                    }
//                }
            
//            VStack {
//                if isIndividual {
//                    createReviewButton
//                } else {
//                    createEventButton
//                }
//                
//                HStack {
//                    Spacer()
//                    createPostButton
//
//                    Spacer()
//                    createStoryButton
                        
//                    Spacer()
//                    
//                }
//                .offset(y: -16)
//            }
//            .font(.custom(Constants.comicFont, size: 16))
//            .tint(.white)
//            .scaleEffect(viewModel.createPostOn ? 1 : 0)
//            .offset(y: viewModel.createPostOn ? 0 : 140)
//            .animation(.easeInOut(duration: 0.4), value: viewModel.createPostOn)
//            .padding(.bottom, 100)
            
            if !viewModel.hideTabBar {
                CustomTabView()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .environmentObject(compassHeading)
                    .environmentObject(gyroManager)
                    .fullScreenCover(isPresented: $viewModel.showCropView) {
                        ImageCropper(image: $viewModel.selectedStoryImage2,
                                     cropShapeType: $viewModel.cropShapeType,
                                     presetFixedRatioType: $viewModel.presetFixedRatioType,
                                     type: $viewModel.cropperType, transformation: $viewModel.transformation, onCropped: { uiImage in
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 ) {
                                viewModel.showCreateStoryScreen(uiImage: uiImage)
                            }
                        })
                        .ignoresSafeArea()
                    }
                    .photosPicker(
                        isPresented: $viewModel.showPicker,
                        selection: $viewModel.photoPickerItems,
                        maxSelectionCount: 1
                    )
                    .fullScreenCover(isPresented: $viewModel.showStoryCameraView) {
                        CameraView(
                            isPresented: $viewModel.showStoryCameraView,
                            onPhotoCaptured: { image in
                                viewModel.handleStoryCameraPhoto(image)
                            },
                            onVideoCaptured: { url in
                                viewModel.handleStoryCameraVideo(url)
                            }
                        )
                        .environmentObject(themeManager)
                    }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.getSubscriptionMeta()
            viewModel.createPostOn = false
            if firstTimeAfterLogin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "you_have_logged_in_successfully".localized(localizationManager.language))
                }
                firstTimeAfterLogin = false
            }
            
//            print(launchViaNotification, "launchViaNotification")
            if viaOtherNotification {
                viewModel.showNotificationScreen()
            } else if viaMessage {
                viewModel.chatNavigationSource = .tab
                viewModel.selectedTab = .chat
                viaMessage = false
            }
            
//            if launchViaNotification {
//                viewModel.showNotificationScreen()
//            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("showNotificationScreen"))) { notification in
            if let userInfo = notification.userInfo,
               let shouldOpen = userInfo["shouldOpen"] as? Bool {
                
                if shouldOpen {
                    viewModel.showNotificationScreen()
                }
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("openChatTab"))) { notification in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.chatNavigationSource = .homeShortcut
                viewModel.selectedTab = .chat
            }
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                print("Continue activity \(userActivity)")
                guard let url = userActivity.webpageURL else {
                        return
                }
                print("User wants to open URL: \(url)")
            handleIncomingURL(url)
        }
        
        .overlay {
            // Black background during modal
            ZStack {
                if viewModel.isUploadingStory || viewModel.uploadedStory {
                    Rectangle()
                        .fill(.black.opacity(0.5))
                        .ignoresSafeArea()
                }
                
                if viewModel.showDialogBox {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                viewModel.showDialogBox.toggle()
                            }
                        }
                }
            }
        }
        .overlay {
            ZStack {
                // story Uploading animation
                if viewModel.isUploadingStory {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        LottieView(animation: .named("Animation-Posting"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                            
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
                
                // Story uploaded animation
                if viewModel.uploadedStory {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.uploadedStory = false
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text("story_uploaded_successfully".localized(localizationManager.language))
                            .withComicFont(12, color: .white)
                            .padding(.bottom, 10)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
                
                // Choose camera or gallery Modal
                if viewModel.showDialogBox {
                    CenterCustomModal(title: "upload".localized(localizationManager.language), leftButtonTitle: "camera".localized(localizationManager.language), rightButtonTitle: "photos".localized(localizationManager.language)) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            viewModel.showDialogBox.toggle()
                        }
                        viewModel.showStoryCameraView.toggle()
                    } onRightButtonPressed: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            viewModel.showDialogBox.toggle()
                        }
                        viewModel.showPicker.toggle()
                    }
                    .transition(.fade)
                }
                
                // Progress Circle
                CustomProgressView(showIndicator: $viewModel.hasSelectedSomeMedia)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                if viewModel.currentTab != .chat {
                    viewModel.checkNotificationStatus()
                }
                
            default:
                break
            }
        }
        .confirmationDialog("Open with", isPresented: $viewModel.showMapOptions) {
            Button("Google Maps") {
                openGoogleMaps(lat: viewModel.selectedLat, lng: viewModel.selectedLng)
            }
            Button("Apple Maps") {
                openAppleMaps(lat: viewModel.selectedLat, lng: viewModel.selectedLng)
            }
        }
        
    }
}


// MARK: - Preview
struct MainTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        MainTabBarView(viewModel: MainTabBarViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}



// MARK: - Components
extension MainTabBarView {
    
    func onTapMapButton(lat: String, lng: String) {
        viewModel.selectedLat = lat
        viewModel.selectedLng = lng
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
    
    
    func openGoogleMaps(lat: String, lng: String) {
        let destination = "\(lat),\(lng)"
        if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
    func openAppleMaps(lat: String, lng: String) {
        let destination = "\(lat),\(lng)"
        if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
            UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
        }
    }
    
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
        } else if url.scheme == "link" {
            
            guard url.host == "tabbar" else { return }
            let urlString = url.absoluteString.replacing("link://tabbar?url=", with: "")
            print(urlString)
            if let newUrl = URL(string: urlString){
                if newUrl.host == Constants.domainName {
                    clearChat = false
                    handleIncomingURL(newUrl)
                } else {
                    UIApplication.shared.open(newUrl)
                }
            }
        } else if url.scheme == "loc" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
                let id = components.path // "1234"
                let lat = queryItems.first(where: { $0.name == "lat" })?.value // "happy"
                let lng = queryItems.first(where: { $0.name == "lng" })?.value // "example"
                
                if let lat, let lng {
                    onTapMapButton(lat: lat, lng: lng)
                }
            }
        } else if url.scheme == "readmore" {
            if let id = url.host {
//                NotificationCenter.default.post(name: .readmore, object: nil, userInfo: ["id": id])
            }
        } else if url.scheme == "tags" {
            if let id = url.host {
//                NotificationCenter.default.post(name: .tags, object: nil, userInfo: ["id": id])
            }
        }
    }
    
    private var tabViewContent: some View {
        TabView(selection: $viewModel.currentTab) {
            HomeView(hideTabBar: $viewModel.hideTabBar, uploadedNewStory: $viewModel.uploadedStory, refreshHomeData: $viewModel.refreshHomeData, createPostOn: $viewModel.createPostOn, onDoubleTap: $viewModel.onDoubleTap, viewModel: HomeViewModel(router: viewModel.router), plusButtonPressed: {
                viewModel.showDialogBox = true
            }, onStoryButtonPressed: {
                withAnimation(.bouncy(duration: 0.3)) {
                    viewModel.showDialogBox.toggle()
                }
            }, onOpenCamera: {
                viewModel.createPostOn = false
                viewModel.showDialogBox = false
                viewModel.showStoryCameraView = true
            }, onScrollChange: { isScrolling in
                viewModel.isScrolling.send(isScrolling)
            })
            .environmentObject(localizationManager)
            .environmentObject(themeManager)
            .tag(TabbedItem.home)
            
            if isIndividual {
                SearchView(hideTabbar: $viewModel.hideTabBar, createPostOn: $viewModel.createPostOn, viewModel: SearchViewModel(router: viewModel.router), onStoryButtonPressed: {
                    withAnimation(.bouncy(duration: 0.3)) {
                        viewModel.showDialogBox.toggle()
                    }
                })
                    .environmentObject(localizationManager)
                    .environmentObject(themeManager)
                    .tag(TabbedItem.search)
                    
                    
            } else {
                InsightsView( viewModel: InsightViewModel(router: viewModel.router), createPostOn: $viewModel.createPostOn, onStoryButtonPressed: {
                    withAnimation(.bouncy(duration: 0.3)) {
                        viewModel.showDialogBox.toggle()
                    }
                })
                    .environmentObject(localizationManager)
                    .environmentObject(themeManager)
                    .tag(TabbedItem.insight)
            }
            
            
            AllChatListView(viewModel: AllChatListViewModel(router: viewModel.router), createPostOn: $viewModel.createPostOn, onStoryButtonPressed: {
                withAnimation(.bouncy(duration: 0.3)) {
                    viewModel.showDialogBox.toggle()
                }
            })
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
            .environmentObject(viewModel)
                .tag(TabbedItem.chat)
            
            UserProfileView(createPostOn: $viewModel.createPostOn, viewModel: UserProfileViewModel(router: viewModel.router), onStoryButtonPressed: {
                withAnimation(.bouncy(duration: 0.3)) {
                    viewModel.showDialogBox.toggle()
                }
            })
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
                .tag(TabbedItem.profile)
        }
    }
    
    
    private var tabBar: some View {
        HStack {
            Spacer()
            tabButton(item: .home)
            Spacer()
            if isIndividual {
                tabButton(item: .search)
            } else {
                tabButton(item: .insight)
            }
            
            Spacer()
            postButton
            
            Spacer()
            tabButton(item: .chat)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(hasReadChat ? 0.0 : 1.0)
//                        .offset(x: -3, y: 5)
                }
            Spacer()
            tabButton(item: .profile)
            Spacer()
        }
        .frame(height: 64)
        .background(
            ZStack {
                Capsule()
                    .fill(.thinMaterial)
                    .preferredColorScheme(.dark)
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(LinearGradient(colors: [themeManager.currentTheme.mediumGray_hmIndigo ,themeManager.currentTheme.mediumGray_hmIndigo , .black.opacity(0.001), themeManager.currentTheme.mediumGray_hmIndigo, themeManager.currentTheme.mediumGray_hmIndigo], startPoint: .leading, endPoint: .trailing))
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, viewModel.hasSafeArea ? 0 : 20)
    }
    
    
    private func tabButton(item: TabbedItem) -> some View {
        VStack(spacing: 4) {
            Image(viewModel.selectedTab == item && !viewModel.createPostOn ? item.iconName + "Selected" : themeManager.darkThemeActive ? item.iconName : item.iconName + "-Dark")
                .animation(.none, value: viewModel.selectedTab)
            if viewModel.selectedTab == item && !viewModel.createPostOn{
                Circle()
                    .fill(.hmIndigo)
                .frame(width: 7)
            }
        }
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                viewModel.createPostOn = false
//                viewModel.navigateTo(screen: viewModel.currentTab.title, open: viewModel.createPostOn)
            }
            if item == .chat {
                viewModel.chatNavigationSource = .tab
            }
            viewModel.sendNotificationOfCurrentTab(currentTab: item)
            viewModel.selectedTab = item
            haptics(.light)
        }
        .onTapGesture(count: 2, perform: {
            if viewModel.selectedTab == .home {
                viewModel.onDoubleTap.toggle()
            }
        })
        .animation(.smooth(duration: 0.3), value: viewModel.selectedTab)
    }
    
    
    private var postButton: some View {
        VStack(spacing: 4) {
            Image("postSelected")
                .renderingMode(.template)
                .foregroundColor(viewModel.createPostOn ? .hmIndigo : themeManager.darkThemeActive ? .white.opacity(0.6) : .hmDarkerGray.opacity(0.6))
                .tint(viewModel.createPostOn ? .hmIndigo : .white.opacity(0.6))
                .rotationEffect(Angle(degrees: viewModel.createPostOn ? 0 : 45))
            if viewModel.createPostOn {
                Circle()
                    .fill(.hmIndigo)
                .frame(width: 7)
            }
        }
        .onTapGesture {
            withAnimation(.smooth) {
                viewModel.createPostOn.toggle()
//                viewModel.navigateTo(screen: viewModel.currentTab.title, open: viewModel.createPostOn)
            }
            haptics(.light)
            
        }
        .animation(.smooth(duration: 0.3), value: viewModel.selectedTab)
    }
    
    
    private var createEventButton: some View {
        Button(action: {
            haptics(.light)
            viewModel.showCreateEventScreen()
            
        }, label: {
            VStack {
                Image("CreateEvent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .overlay {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.1))
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 3)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 4)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 5)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 6)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 7)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 8)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 9)
                                .fill(.black.opacity(0.04))
                            Circle()
                                .stroke(lineWidth: 10)
                                .fill(.black.opacity(0.03))
                            Circle()
                                .stroke(lineWidth: 11)
                                .fill(.black.opacity(0.02))
                            Circle()
                                .stroke(lineWidth: 12)
                                .fill(.black.opacity(0.01))
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    }
                Text("create_event".localized(localizationManager.language))
            }
        })
    }
    
    
    private var createReviewButton: some View {
        Button(action: {
            haptics(.light)
            viewModel.showCreateReviewScreen()
            
        }, label: {
            VStack {
                Image("ReviewIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .overlay {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.1))
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 3)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 4)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 5)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 6)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 7)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 8)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 9)
                                .fill(.black.opacity(0.04))
                            Circle()
                                .stroke(lineWidth: 10)
                                .fill(.black.opacity(0.03))
                            Circle()
                                .stroke(lineWidth: 11)
                                .fill(.black.opacity(0.02))
                            Circle()
                                .stroke(lineWidth: 12)
                                .fill(.black.opacity(0.01))
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    }
                Text("review".localized(localizationManager.language))
            }
        })
    }
    
    
    private var createPostButton: some View {
        Button(action: {
            haptics(.light)
            viewModel.showCreatePostScreen()
//            viewModel.navigateTo(screen: "home-create-post")
        }, label: {
            VStack {
                Image("CreatePost")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .overlay {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.1))
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 3)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 4)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 5)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 6)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 7)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 8)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 9)
                                .fill(.black.opacity(0.04))
                            Circle()
                                .stroke(lineWidth: 10)
                                .fill(.black.opacity(0.03))
                            Circle()
                                .stroke(lineWidth: 11)
                                .fill(.black.opacity(0.02))
                            Circle()
                                .stroke(lineWidth: 12)
                                .fill(.black.opacity(0.01))
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    }
                Text("create_post".localized(localizationManager.language))
            }
        })
    }
    
    
    private var createStoryButton: some View {
        Button(action: {
            haptics(.light)
            withAnimation(.bouncy(duration: 0.3)) {
                viewModel.showDialogBox.toggle()
            }
            viewModel.createPostOn.toggle()
        }, label: {
            VStack(alignment: .center) {
                Image("CreateStory")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .overlay {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.1))
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 2)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 3)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 4)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 5)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 6)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 7)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 8)
                                .fill(.black.opacity(0.05))
                            Circle()
                                .stroke(lineWidth: 9)
                                .fill(.black.opacity(0.04))
                            Circle()
                                .stroke(lineWidth: 10)
                                .fill(.black.opacity(0.03))
                            Circle()
                                .stroke(lineWidth: 11)
                                .fill(.black.opacity(0.02))
                            Circle()
                                .stroke(lineWidth: 12)
                                .fill(.black.opacity(0.01))
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    }
                Text("create_story".localized(localizationManager.language))
            }
        })
    }
    
}
