//
//  HomeViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import AVFoundation


class HomeViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = HomeDataManager()
    let profileDataManager = ProfileDataManager()
    let postDataManager = PostDataManager()
    let storyDataManager = StoryDataManager()
    var cancellables = Set<AnyCancellable>()
    var navigationScreen: NavigationScreen? = nil
    var currentPageNo: Int = 1
    var totalPages: Int = 1
    var allPosts: [PostData] = []
    var commentSectionPostID: String = ""
    var gotCurrentLocation: Bool = false
    @Published var refreshData: Bool = false
    @Published var showTopBar: Bool = true
    @Published var newPostData: [PostData] = []
    @Published var emptyPostArray: [DummyPostModel] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var refreshPost: Bool = false
    @Published var showDot: Bool = false
    @Published var isStoriesPresented: Bool = false
    @Published var stories: [THMStoryUIModel] = []
    @Published var myStories: [THMStoryUIModel] = []
    @Published var otherStories: [THMStoryUIModel] = []
    @Published var joinedEventID: String = ""
    @Published var storyDataPageNo: Int = 1
    @Published var storyDataTotalPages: Int = 1
    @Published var loadingStories: Bool = false
    @Published var showPostOptionView: Bool = false
    @Published var postOptionYOffset: CGFloat = 0
    @Published var loadingHomeData: Bool = false
    @Published var createdNewContent: Bool = false
    @Published var selectedStoryIndex: Int = 0
    @Published var showStoryScreen: Bool = false
    
    @Published var refreshPostView: Bool = false
    @State var createPostOn: Bool = false
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    @Published var currentLat: Double = 20.5937
    @Published var currentLng: Double = 78.9629
    
    @AppStorage("name") var name: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    @AppStorage("email") var email: String = ""
    @AppStorage("phoneNumber") var phoneNumber: String = ""
    @AppStorage("dialCode") var dialCode: String = ""
    @AppStorage("locationString") var locationString: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
//    @AppStorage("isMute") var isMute: Bool = false
    @AppStorage("pdfLimit") var pdfLimit: Double = 5.0
    @AppStorage("videoLimit") var videoLimit: Double = 30
    @AppStorage("hasSubscription") var hasSubscription: Bool = false
    
    let locationManager = LocationManager()
    
    private var homeDataTask: Task<Void, Never>?
    private var storyDataTask: Task<Void, Never>?
    private var locationCancellable: AnyCancellable? = nil
    var navigatedToNotification: Bool = false
    
    let cacheManager = THMCacheManager.shared
    
    init(router: AnyRouter) {
        self.router = router
        UserDefaultsManager.shared.setMuteStatus(true)
        getProfileData()
        getLocationAndHomeData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            if !gotCurrentLocation {
                getHomeData(page: 1, refreshedData: true, suggestion: true)
            }
        }
//        getHomeData(page: 1, refreshedData: true, suggestion: true)
//        addDummyStories()
    }
    
    
    func getLocationAndHomeData() {
        locationManager.requestLocation()
        locationCancellable = locationManager.$currentLocation
            .sink(receiveValue: { [weak self] coordinates in
                guard let self else { return }
                if let coordinates {
                    currentLat = coordinates.latitude.magnitude
                    currentLng = coordinates.longitude.magnitude
                    gotCurrentLocation = true
                    getHomeData(page: 1, refreshedData: true, suggestion: true)
                    locationCancellable?.cancel()
                    locationCancellable = nil
                }
            })
    }
    
    
    func showNotificationScreen() {
        navigatedToNotification = true
        onNavigate(bool: true)
        router.showScreen(.push) { router in
            NotificationView(viewModel: NotificationViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSinglePostView(id: String) {
        router.showScreen(.push) { newRouter in
            SinglePostView(viewModel: SinglePostViewModel(router: newRouter, postID: id), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSearchScreen() {
        router.showScreen(.push) { router in
            SearchView(hideTabbar: .constant(true), createPostOn: .constant(false), viewModel: SearchViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView2(viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
//        router.showScreen(.push) { router in
//            UserProfileView(createPostOn: .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
//                .environmentObject(ThemeManager.shared)
//                .navigationBarBackButtonHidden()
//        }
    }
    
    
    func showCreatePostScreen() {
        router.showScreen(.push) { router in
            CreatePostScreen(viewModel: CreatePostViewModel(router: router, onPostCreated: { [weak self] in
                guard let self else { return }
                createdNewContent = true
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                guard let self else { return }
                createdNewContent = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCreateEventScreen() {
        router.showScreen(.push) { router in
            CreateEventScreen(viewModel: CreateEventViewModel(router: router, onEventCreated: { [weak self] in
                guard let self else { return }
                createdNewContent = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showEventDetailScreen(id: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: id), onPressedJoin: { [weak self] eventID in
                guard let self else { return }
                
                if var event = allPosts.first(where: {$0.id == eventID}) {
                    if let imJoining = event.imJoining {
                        event.imJoining = !imJoining
                    } else {
                        event.imJoining = true
                    }
                    
                    if let index = allPosts.firstIndex(where: { $0.id == eventID }) {
                        allPosts[index] = event
                    }
                }
                
                
            }, onPressedShare: { [weak self] eventID in
                guard let self else { return }
                
                if var event = allPosts.first(where: {$0.id == eventID}) {
                    if let savedByMe = event.savedByMe {
                        event.savedByMe = !savedByMe
                    } else {
                        event.savedByMe = true
                    }
                    
                    if let index = allPosts.firstIndex(where: { $0.id == eventID }) {
                        allPosts[index] = event
                    }
                }
            })
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showStoryScreen(index: Int = 0) {
        router.showScreen(.fullScreenCover) { router in
            THMStoryView(stories: self.stories, selectedIndex: index, router: router) { story, message, emoji, isLiked in
                print(story, message ?? "😃")
            } onDeleteStory: { [weak self] index in
                guard let self else { return }
//
//                myStories[0].stories.remove(at: index)
//                if myStories[0].stories.isEmpty {
//                    myStories.removeAll()
//                }
            } onDismiss: { [weak self] in
                guard let self else { return }
                getStories(refreshData: true, pageNo: 1)
                if !UserDefaultsManager.shared.getMuteStatus() {
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
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func connectSocket() {
        SocketIOViewModel.shared.configureSocket()
    }
    
}


extension NSNotification.Name {
    static let pauseAllVideoNotification = NSNotification.Name("pauseAllVideoNotification")
}

// MARK: - Cancelling Task
extension HomeViewModel {
    func cancelHomeDataTask() {
        showLoadingIndicator = false
        homeDataTask?.cancel()
        homeDataTask = nil
        
        print("Home Data Task Cancelled")
    }
    
    
    func cancelStoryDataTask() {
        loadingStories = false
        storyDataTask?.cancel()
        storyDataTask = nil
    }
}


// MARK: - Networking
extension HomeViewModel {
    
    func getHomeData(page: Int, refreshedData: Bool = false, showLoadingIndicator: Bool = true, suggestion: Bool = false, onCompletion: (([PostData], Bool) -> Void)? = nil) {
        guard page <= totalPages else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.loadingHomeData = true
            self.showLoadingIndicator = showLoadingIndicator
        }
        homeDataTask?.cancel()
        homeDataTask = Task {
            do {
                let result = try await dataManager.getHomeData(pageNo: page, suggestion: suggestion, lat: currentLat, lng: currentLng)
                
                await MainActor.run {
                    loadingHomeData = false
                    self.showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if let data = result.data {
                            if refreshedData {
                                allPosts.removeAll()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                                    guard let self else { return }
//                                    onCompletion?(data, refreshedData)
                                    allPosts = data
                                    currentPageNo = result.pageNo ?? 1
                                    totalPages = result.totalPages ?? 1
                                    refreshPostView.toggle()
                                }
                                
                                
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//                                    guard let self else { return }
//                                    self.isMute = false
//                                }
                            } else {
                                allPosts.append(contentsOf: data)
//                                onCompletion?(data, refreshedData)
                                currentPageNo = result.pageNo ?? 1
                                totalPages = result.totalPages ?? 1
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
    func getSubscriptionMeta() {
        Task {
            let result = try await dataManager.getSubscriptionMeta()
            
            await MainActor.run {
                let range = 200...204
                
                if result.status && range.contains(result.statusCode) {
                    if let uploadLimit = result.data?.uploadLimit {
                        for limit in uploadLimit {
                            if let fileType = limit.fileType,
                               let size = limit.size {
                                if fileType == "pdf" {
                                    pdfLimit = Double(size)
                                    print(pdfLimit)
                                } else if fileType == "video" {
                                    videoLimit = Double(size)
                                    print(videoLimit)
                                    }
                            }
                        }
                    }
                    
                    if let hasSub = result.data?.hasSubscription {
                        hasSubscription = hasSub
                    }
                }
            }
        }
    }
}


// MARK: - GettingProfileDetails
extension HomeViewModel {
    func getProfileData() {
        
        Task {
            do {
                let result = try await profileDataManager.getProfile()
                
                await MainActor.run {
                    
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if data.accountType == "individual" {
                                name = data.name ?? ""
                                profilePic = data.profilePic?.small ?? ""
                                ownUserID = data.id ?? ""
                                isIndividual = true
                                locationString = ""
                                email = data.email ?? ""
                                phoneNumber = data.phoneNumber ?? ""
                                dialCode = data.dialCode ?? ""
                            } else{
                                
                                if let businessProfileRef = data.businessProfileRef {
                                    name = businessProfileRef.name ?? ""
                                    profilePic = businessProfileRef.profilePic?.small ?? ""
                                    ownUserID = data.id ?? ""
                                    isIndividual = false
                                    
                                    if let address = businessProfileRef.address {
                                        locationString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                                    }
                                    
                                    // These are business email and phone number and not manager detail use accordingly.
                                    email = data.businessProfileRef?.email ?? ""
                                    phoneNumber = data.businessProfileRef?.phoneNumber ?? ""
                                    dialCode = data.businessProfileRef?.dialCode ?? ""
                                }
                            }
                            
                            username = data.username ?? ""
                            
                            // Checking if socket has been disconnected, then reconnecting socket.
                            if !SocketIOViewModel.shared.isConnected {
                                connectSocket()
                            }
                        }
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
}


// MARK: - Story
extension HomeViewModel {
    func getStories(refreshData: Bool = true, pageNo: Int = 1) {
        
        guard pageNo <= storyDataTotalPages else { return }
        
        storyDataTask?.cancel()
        
        storyDataTask = Task {
            do {
                await MainActor.run {
                    loadingStories = true
                }
                
                let result = try await storyDataManager.getStories(pageNo: pageNo)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data,
                           let myStories = data.myStories,
                           let stories = data.stories {
                            if refreshData && !myStories.isEmpty {
                                mapToMyStoris(stories: myStories)
                            }
                            
                            if myStories.isEmpty {
                                self.myStories.removeAll()
                            }
                            
                            mapToOtherStories(storyUsers: stories, refreshData: refreshData)
                        }
                        
                        storyDataPageNo = result.pageNo ?? 1
                        storyDataTotalPages = result.totalPages ?? 1
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self else { return }
                        loadingStories = false
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func mapToMyStoris(stories: [MyStory]) {
        var thmStories: [THMStory] = []
        
        for story in stories {
            if let createdAt = story.createdAt,
               let sourceURL = story.sourceURL,
               let likesRef = story.likesRef,
               let viewsRef = story.viewsRef,
               let mimeType = story.mimeType,
               let duration = story.duration,
               let id = story.id,
               let mediaID = story.mediaID{
                if mimeType == "video/mp4" {
                    thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, likesRef: likesRef, viewsRef: viewsRef, duration: duration, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .video)))
                } else {
                    thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, likesRef: likesRef, viewsRef: viewsRef, duration: duration + 10.0, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .image )))
                }
            }
        }
        
        // Sort stories by createdAt date (oldest first, like Instagram)
        thmStories.sort { story1, story2 in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date1 = formatter.date(from: story1.date) ?? ISO8601DateFormatter().date(from: story1.date),
                  let date2 = formatter.date(from: story2.date) ?? ISO8601DateFormatter().date(from: story2.date) else {
                return false
            }
            return date1 < date2
        }
        
        let myStoryUIModel = THMStoryUIModel(user: THMStoryUIUser(name: name, image: profilePic), stories: thmStories, isMyStory: true)
        
        myStories = [myStoryUIModel]
    }
    
    
    func mapToOtherStories(storyUsers: [StoryUser], refreshData: Bool) {
        
        var otherStoryUserArray: [THMStoryUIModel] = []
        
        for user in storyUsers {
            var thmStories: [THMStory] = []
            
            if let storiesRef = user.storiesRef, !storiesRef.isEmpty {
                
                for story in storiesRef {
                    if let createdAt = story.createdAt,
                       let sourceURL = story.sourceURL,
                       let likedByMe = story.likedByMe,
                       let mimeType = story.mimeType,
                       let duration = story.duration,
                       let id = story.id,
                       let mediaID = story.mediaID {
                        if mimeType == "video/mp4" {
                            thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, isLiked: likedByMe, duration: duration, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .video)))
                        } else {
                            thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, isLiked: likedByMe, duration: duration + 10.0, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .image )))
                        }
                    }
                }
                
                // Sort stories by createdAt date (oldest first, like Instagram)
                thmStories.sort { story1, story2 in
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    guard let date1 = formatter.date(from: story1.date) ?? ISO8601DateFormatter().date(from: story1.date),
                          let date2 = formatter.date(from: story2.date) ?? ISO8601DateFormatter().date(from: story2.date) else {
                        return false
                    }
                    return date1 < date2
                }
                
            } else {
                continue
            }
            
            if user.accountType == "individual" {
                
                otherStoryUserArray.append(THMStoryUIModel(user: THMStoryUIUser(id: user.id ?? "", name: user.name ?? "", image: user.profilePic?.small ?? "", username: user.username ?? ""),isSeen: user.seenByMe ?? false, stories: thmStories))
            } else {
                otherStoryUserArray.append(THMStoryUIModel(user: THMStoryUIUser(id: user.id ?? "", name: user.businessProfileRef?.name ?? "", image: user.businessProfileRef?.profilePic?.small ?? "", username: user.businessProfileRef?.username ?? ""),isSeen: user.seenByMe ?? false, stories: thmStories))
            }
        }
        
        if refreshData {
            otherStories = otherStoryUserArray
        } else {
            otherStories.append(contentsOf: otherStoryUserArray)
        }
    }
    
    
//    func reportPost(id: String) {    
//        Task {
//            do {
//                let result = try await postDataManager.reportPost(id: id)
//                
//                await MainActor.run {
//                    let range = 200...204
//                    
//                    if result.status  && range.contains(result.statusCode) {
//                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
//                    }
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
    
    
    func onNavigate(bool: Bool) {
        NotificationCenter.default.post(name: .onNavigate, object: nil, userInfo: ["onNavigate" : bool])
    }
    
    
    func setMuteStatus(bool: Bool) {
        NotificationCenter.default.post(name: .setMuteStatus, object: nil, userInfo: ["setMuteStatus" : bool])
    }
}

extension Notification.Name {
    static let onNavigate = Notification.Name("onNavigate")
    static let setMuteStatus = Notification.Name("setMuteStatus")
}


