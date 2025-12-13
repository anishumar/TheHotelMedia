//
//  BusinessProfileViewModel.swift
//  HotelMedia
//
//  Created by MAC on 20/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


struct Amenity: Identifiable {
    let id = UUID().uuidString
    var title: String
    var image: String
}

class UserProfileViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = ProfileDataManager()
    let storyDataManager = StoryDataManager()
    let connectionDataManager = UserConnectionsDataManager()
    let checkInDataManager = PlacesDataManager()
    let postDataManager = PostDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var isPrivateAccount: Bool = false
    @Published var publicProfileID: String = ""
    @Published var sharedByProfileID: String? = nil
    var userProfileID: String = ""
    @Published var currentTab: ProfileTab = .photos
    @Published var photosArray: [MediaRef] = []
    @Published var reviewsArray: [String] = []
    var currentPage = 20
    @Published var height: CGFloat = 200
    @Published var profileData: ProfileData? = nil
    var errorText: String = ""
    @Published var showLoadingIndicator: Bool = false
    var loadPostData: Bool = true
    @Published var loadingPostData: Bool = false
    @Published var totalPostData: [PostData] = []
    var postDataPageNo: Int = 1
    var postDataTotalPages: Int = 1
    var imageDataPageNo: Int = 1
    var imageDataTotalPages: Int = 1
    var loadImageData: Bool = true
    @Published var loadingImageData: Bool = false
    @Published var videosArray: [MediaRef] = []
    //    @Published var videosArray2: [MediaRef] = []
    @Published var followButtonEnabled: Bool = true
    @Published var showOptionView: Bool = false
    @Published var isBlockedByMe: Bool = false
    @Published var isOfficial: Bool = false
    @Published var showBlockModalView: Bool = false
    @Published var toShowLocationString: String = ""
    @Published var showMapOptions: Bool = false
    var businessReviewProfile: ProfileData? = nil
    
    var videoDataPageNo: Int = 1
    var videoDataTotalPages: Int = 1
    var loadVideoData: Bool = true
    @Published var loadingVideoData: Bool = false
    @Published var savedByMe: Bool = false
    
    // Story
    @Published var loadingProfileStory: Bool = false
    @Published var profileStories: [THMStoryUIModel] = []
    
    
    @Published var totalReviewData: [PostData] = []
    var reviewDataPageNo: Int = 1
    var reviewDataTotalPages: Int = 1
    var loadReviewData: Bool = true
    @Published var loadingReviewData: Bool = false
    
    var userFullName: String = ""
    @Published var userProfilePic: String = ""
    var userLocationString: String = ""
    @Published var userIsIndividual: Bool = false
    
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var selectedVideoMedia: MediaType = .video(urlString: "")
    @Published var showPreview: Bool = false
    @Published var showVideoPreview: Bool = false
    @Published var showPhotoDetailScreen: Bool = false
    @Published var selectedPhotoIndex: Int = 0
    @Published var selectedPhotoMediaID: String? = nil
    @Published var showVideoDetailScreen: Bool = false
    @Published var selectedVideoMediaID: String? = nil
    
    @Published var showPostOptionView: Bool = false
    @Published var isReviewPost: Bool = false
    @Published var postOptionYOffset: CGFloat = 0
    @Published var selectedPostID: String = ""
    
    @AppStorage("name") var name: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    @AppStorage("emailID") var emailID: String = ""
    @AppStorage("locationString") var locationString: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    @AppStorage("privateAccount") var privateAccount: Bool = false
    @AppStorage("notificationEnabled") var notificationEnabled: Bool = true
    
    @Published var isSharePresented: Bool = false
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com")!
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    @Published var showBigProfilePic: Bool = false
    
    var weatherIcon: CurrentValueSubject<String?, Never> = .init(nil)
    var weatherTitle: CurrentValueSubject<String?, Never> = .init(nil)
    @Published var showWeatherAmenity: Bool = false
    
    private var timerCancellable: AnyCancellable?
    
    var tempRangeTitle: String? = nil
    var aqiTitle: String? = nil
    var currentWeatherDetail = ""
    
    let localizationManager = LocalizationManager.shared
    
    
    init(router: AnyRouter, publicProfileID: String = "", sharedByProfileID: String? = nil) {
        self.router = router
        self.publicProfileID = publicProfileID
        self.sharedByProfileID = sharedByProfileID
        addSubscribers()
        startTimer()
        if !publicProfileID.isEmpty {
            getProfileData()
        }
        if let sharedByProfileID, !publicProfileID.isEmpty {
            if let encryptedSharedID = EncryptionHelper.encrypt(publicProfileID),
               let encryptedSharedByID = EncryptionHelper.encrypt(sharedByProfileID) {
                sharedProfile(sharedID: encryptedSharedID, sharedByID: encryptedSharedByID)
            }
        }
    }
    
    
    func startTimer() {
        timerCancellable = Timer
            .publish(every: 3.0, on: .main, in: .common) // every 1 second
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if currentWeatherDetail == "temp" {
                    if let aqiTitle, aqiTitle.isNotEmpty {
                        weatherTitle.send(aqiTitle)
                        weatherIcon.send("AQI")
                        currentWeatherDetail = "aqi"
                    }
                    
                } else if currentWeatherDetail == "aqi" {
                    if let tempRangeTitle, tempRangeTitle.isNotEmpty {
                        weatherTitle.send(tempRangeTitle)
                        weatherIcon.send("summer")
                        currentWeatherDetail = "temp"
                    }
                } else {
                    if let tempRangeTitle, tempRangeTitle.isNotEmpty {
                        weatherTitle.send(tempRangeTitle)
                        weatherIcon.send("summer")
                        currentWeatherDetail = "temp"
                        return
                    }
                    
                    if let aqiTitle, aqiTitle.isNotEmpty {
                        weatherTitle.send(aqiTitle)
                        weatherIcon.send("AQI")
                        currentWeatherDetail = "aqi"
                        return
                    }
                }
                
                guard showWeatherAmenity != currentWeatherDetail.isNotEmpty else { return }
                showWeatherAmenity = currentWeatherDetail.isNotEmpty
            }
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    
    func addSubscribers() {
        $profileData
            .sink { [weak self] data in
                guard let self else { return }
                if let data {
                    
                    if publicProfileID.isEmpty {
                        if data.accountType == "individual" {
                            profilePic = data.profilePic?.small ?? ""
                            name = data.name ?? ""
                            isIndividual = true
                            emailID = data.email ?? ""
                            
                            if let address = data.address {
                                locationString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                            } else {
                                locationString = ""
                            }
                            
                        } else if data.accountType == "business" {
                            profilePic = data.businessProfileRef?.profilePic?.small ?? ""
                            name = data.businessProfileRef?.name ?? ""
                            
                            if let address = data.businessProfileRef?.address {
                                locationString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                                
                                
                            } else {
                                locationString = ""
                            }
                            isIndividual = false
                            
                            emailID = data.email ?? ""
                        }
                        
                        ownUserID = data.id ?? ""
                        privateAccount = data.privateAccount ?? true
                        notificationEnabled = data.notificationEnabled ?? true
                    }
                    
                    
                    if !publicProfileID.isEmpty {
                        if let role = data.role, role == "official" {
                            isOfficial = true
                        }
                    }
                    
                    
                    
                    if data.accountType == "individual" {
                        userProfilePic = data.profilePic?.small ?? ""
                        userFullName = data.name ?? ""
                        userIsIndividual = true
                        
                    } else if data.accountType == "business"{
                        userProfilePic = data.businessProfileRef?.profilePic?.small ?? ""
                        userFullName = data.businessProfileRef?.name ?? ""
                        
                        if let address = data.businessProfileRef?.address {
                            userLocationString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                            
                            toShowLocationString = "\(address.city ?? ""), \(address.state ?? ""), \(address.country ?? "")"
                        }
                        userIsIndividual = false
                        
                        viewedProfile(id: data.businessProfileID ?? "")
                    }
                    
                    isBlockedByMe = data.isBlockedByMe ?? false
                    
                    let degreeSymbol = "\u{00B0}"
                    let minTemp = data.weather?.main?.feelsLike ?? 273.15
                    let maxTemp = data.weather?.main?.tempMax ?? 273.15
                    
                    let minTempInC = Int(minTemp - 273.15)
                    let maxTempInC = Int(maxTemp - 273.15)
                    
                    
                    
                    if data.weather == nil {
                        tempRangeTitle = "N/A"
                    } else {
                        tempRangeTitle = "\(minTempInC)\(degreeSymbol)C - \(maxTempInC)\(degreeSymbol)C"
                    }
                    
                    weatherTitle.send(tempRangeTitle)
                    weatherIcon.send("summer")
                    currentWeatherDetail = "temp"
                    showWeatherAmenity = true
                    
                    if let list = data.weather?.airPollution?.list, list.isNotEmpty {
                        let aqiData = list[0]
                        if let components = aqiData.components {
                            if let pm2_5 = components["pm2_5"] {
                                let aqiInt = pm2_5.toAQI()
                                aqiTitle = "AQI \(aqiInt)"
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        //        $videosArray
        //            .sink { [weak self] mediaArray in
        //                guard let self else { return }
        //
        //                self.loadingVideoData = true
        //
        //                Task {
        //
        //                    let mediaWithThumbnails = await self.fetchThumbnailImages(mediaArray: mediaArray)
        //
        //                    await MainActor.run {
        //                        self.loadingVideoData = false
        //                        var newArray = mediaArray
        //
        //                        for mediaWithThumbnail in mediaWithThumbnails {
        //                            for (index,media) in self.videosArray.enumerated() {
        //                                if media.id == mediaWithThumbnail.id {
        //                                    newArray[index] = mediaWithThumbnail
        //                                    break
        //                                }
        //
        //                            }
        //                        }
        //                        print(self.videosArray)
        //                        self.videosArray2 = newArray
        //                    }
        //                }
        //            }
        //            .store(in: &cancellables)
    }
    
    
    func fetchThumbnailImages(mediaArray: [MediaRef]) async -> [MediaRef] {
        await withTaskGroup(of: MediaRef?.self) { group -> [MediaRef] in
            var results: [MediaRef] = []
            
            for media in mediaArray {
                group.addTask { await self.generateImage(media: media) }
            }
            
            // Collect results as tasks complete
            for await result in group {
                if let validMedia = result {
                    results.append(validMedia)
                }
            }
            return results
        }
    }
    
    
    func generateImage(media: MediaRef) async -> MediaRef? {
        
        var newMedia = media
        
        guard media.mediaType == "video" else { return nil }
        
        if let image = try? await URL(string: media.sourceURL ?? "")!.generateVideoThumbnail() {
            newMedia.videoThumbnail = image
            return newMedia
        } else {
            return nil
        }
    }
    
    
    
    func changeHeight() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.height = 800
        }
    }
    
    
    func showSettingScreen() {
        router.showScreen(.push) { router in
            SettingsViews(viewModel: SettingsViewsModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func openPhotoDetail(at index: Int) {
        guard photosArray.indices.contains(index) else { return }
        let mediaID = photosArray[index].id
        selectedPhotoIndex = index
        selectedPhotoMediaID = mediaID
        showPhotoDetailScreen = true
    }
    
    
    func showEditProfileScreen(profileData: ProfileData) {
        router.showScreen(.push) { router in
            EditProfileView(viewModel: EditProfileViewModel(router: router, profileData: profileData))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showFollowersListScreen(show: String) {
        if publicProfileID.isEmpty {
            router.showScreen(.push) { router in
                FollowerListView(viewModel: FollowerListViewModel(router: router, id: self.userProfileID, username: self.profileData?.username ?? "", currentTab: show))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        } else {
            if isPrivateAccount {
                if let isConnected = profileData?.isConnected {
                    if isConnected {
                        router.showScreen(.push) { router in
                            FollowerListView(viewModel: FollowerListViewModel(router: router, id: self.publicProfileID, username: self.profileData?.username ?? "", currentTab: show))
                                .environmentObject(ThemeManager.shared)
                                .navigationBarBackButtonHidden()
                        }
                    }
                }
            } else {
                router.showScreen(.push) { router in
                    FollowerListView(viewModel: FollowerListViewModel(router: router, id: self.publicProfileID, username: self.profileData?.username ?? "", currentTab: show))
                        .environmentObject(ThemeManager.shared)
                        .navigationBarBackButtonHidden()
                }
            }
        }
        
    }
    
    
    func showCreateReviewScreen(profile: ProfileData) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, reviewPlace: profile))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showBlockModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_you_really_want_to_block_this_user".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) {
                self.blockUser()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showUnblockModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_really_want_to_unblock_this_user".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) {
                self.blockUser()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showShareView() {
        
        let baseURLString = "https://thehotelmedia.com/share/users"
        
        if !publicProfileID.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedToShareProfileID = EncryptionHelper.encrypt(publicProfileID),
               let encryptedSharedByProfileID = EncryptionHelper.encrypt(ownUserID) {
                
                shareURL = URL(string: "\(baseURLString)?id=\(encryptedToShareProfileID)&userID=\(encryptedSharedByProfileID)")!
                isSharePresented.toggle()
                
            }
            
        } else if !ownUserID.isEmpty {
            
            if let encryptedProfileID = EncryptionHelper.encrypt(ownUserID) {
                shareURL = URL(string: "\(baseURLString)?id=\(encryptedProfileID)&userID=\(encryptedProfileID)")!
                isSharePresented.toggle()
            }
        }
    }
    
    
    func showChatScreen() {
        router.showScreen(.push) { router in
            if let username = self.profileData?.username {
                ChatView(viewModel: ChatViewModel(router: router, username: username, userID: self.profileData?.id ?? "", profilePic: self.userProfilePic, name: self.userFullName, lastScreen: "profile"), onLeaveChat: { returnedUsername in
                    SocketIOViewModel.shared.leavePrivateChatEmit(user: username)
                })
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showProfileStoryOrFallback(_ fallback: @escaping () -> Void) {
        guard !userProfileID.isEmpty else {
            fallback()
            return
        }
        
        Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                loadingProfileStory = true
            }
            
            do {
                let response = try await storyDataManager.getStories(pageNo: 1)
                let range = 200...204
                var foundStories: [THMStoryUIModel] = []
                
                if response.status,
                   let statusCode = response.statusCode as Int?,
                   range.contains(statusCode),
                   let storyUsers = response.data?.stories,
                   let userStories = storyUsers.first(where: { $0.id == userProfileID }) {
                    
                    if let mapped = mapStoryUserToTHMModel(userStories) {
                        foundStories = [mapped]
                    }
                }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    loadingProfileStory = false
                    profileStories = foundStories
                    
                    if !foundStories.isEmpty {
                        UserDefaultsManager.shared.setMuteStatus(true)
                        router.showScreen(.fullScreenCover) { router in
                            THMStoryView(
                                stories: foundStories,
                                selectedIndex: 0,
                                router: router,
                                onDismiss: {
                                    UserDefaultsManager.shared.setMuteStatus(false)
                                }
                            )
                            .environmentObject(ThemeManager.shared)
                            .navigationBarBackButtonHidden()
                        }
                    } else {
                        fallback()
                    }
                }
                
            } catch {
                await MainActor.run { [weak self] in
                    self?.loadingProfileStory = false
                    fallback()
                }
            }
        }
    }
    
    
    private func mapStoryUserToTHMModel(_ user: StoryUser) -> THMStoryUIModel? {
        guard let storiesRef = user.storiesRef, !storiesRef.isEmpty else { return nil }
        
        var thmStories: [THMStory] = []
        
        for story in storiesRef {
            if let createdAt = story.createdAt,
               let sourceURL = story.sourceURL,
               let likedByMe = story.likedByMe,
               let mimeType = story.mimeType,
               let duration = story.duration,
               let id = story.id,
               let mediaID = story.mediaID {
                if mimeType == "video/mp4" {
                    // Ensure minimum 15 seconds for videos
                    let videoDuration = max(duration, 15.0)
                    thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, isLiked: likedByMe, duration: videoDuration, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .video)))
                } else {
                    // Ensure minimum 15 seconds for images
                    let imageDuration = max(duration + 10.0, 15.0)
                    thmStories.append(THMStory(id: id, mediaID: mediaID ,mediaURL: sourceURL, date: createdAt, isLiked: likedByMe, duration: imageDuration, config: .init(storyType: .plain(config: .init(showLikeButton: false)), mediaType: .image )))
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
        
        guard !thmStories.isEmpty else { return nil }
        
        if user.accountType == "individual" {
            return THMStoryUIModel(user: THMStoryUIUser(id: user.id ?? "", name: user.name ?? "", image: user.profilePic?.small ?? "", username: user.username ?? ""),isSeen: user.seenByMe ?? false, stories: thmStories)
        } else {
            return THMStoryUIModel(user: THMStoryUIUser(id: user.id ?? "", name: user.businessProfileRef?.name ?? "", image: user.businessProfileRef?.profilePic?.small ?? "", username: user.businessProfileRef?.username ?? ""),isSeen: user.seenByMe ?? false, stories: thmStories)
        }
    }
    
    
    
    
    func showEventDetailScreen(id: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: id), onPressedJoin: { [weak self] eventID in
                guard let self else { return }
                
                if var event = totalPostData.first(where: {$0.id == eventID}) {
                    if let imJoining = event.imJoining {
                        event.imJoining = !imJoining
                    } else {
                        event.imJoining = true
                    }
                    
                    if let index = totalPostData.firstIndex(where: { $0.id == eventID }) {
                        totalPostData[index] = event
                    }
                }
                
                
            }, onPressedShare: { [weak self] eventID in
                guard let self else { return }
                
                if var event = totalPostData.first(where: {$0.id == eventID}) {
                    if let savedByMe = event.savedByMe {
                        event.savedByMe = !savedByMe
                    } else {
                        event.savedByMe = true
                    }
                    
                    if let index = totalPostData.firstIndex(where: { $0.id == eventID }) {
                        totalPostData[index] = event
                    }
                }
            })
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func showDeletePostModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_you_really_want_to_delete_this_post".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) {
                self.deletePost(id: self.selectedPostID) {
                    if let index = self.totalPostData.firstIndex(where: {$0.id == self.selectedPostID}) {
                        self.totalPostData.remove(at: index)
                    }
                }
                
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showCreatePostScreen() {
        router.showScreen(.push) { router in
            CreatePostScreen(viewModel: CreatePostViewModel(router: router, onPostCreated: { [weak self] in
                guard let self else { return }
                
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditPostScreen() {
        guard let postData = totalPostData.first(where: { $0.id == selectedPostID }) else {
            return
        }
        
        router.showScreen(.push) { router in
            EditPostScreen(viewModel: EditPostViewModel(router: router, postData: postData, onPostUpdated: { [weak self] in
                guard let self else { return }
                // Ensure we're on the posts tab
                self.currentTab = .posts
                // Reload all posts to ensure the view updates properly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.reloadPosts()
                }
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                guard let self else { return }
                //                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showCreateEventScreen() {
        router.showScreen(.push) { router in
            CreateEventScreen(viewModel: CreateEventViewModel(router: router, onEventCreated: { [weak self] in
                guard let self else { return }
                //                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showBookingInfoScreen() {
        router.showScreen(.push) { router in
            BookingInfoView(viewModel: BookingInfoViewModel(router: router, profileData: self.profileData))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBookTableScreen() {
        if let profileData {
            router.showScreen(.push) { router in
                BookingTableInfoView(viewModel: BookingTableInfoViewModel(router: router, profileData: profileData))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    func showBookBanquetScreen() {
        if let profileData {
            router.showScreen(.push) { router in
                BookingBanquetInfoView(viewModel: BookingBanquetInfoViewModel(router: router, profileData: profileData))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
}


// MARK: - Networking
extension UserProfileViewModel {
    func getProfileData() {
        if profileData == nil {
            showLoadingIndicator = true
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if self.publicProfileID.isEmpty {
                    let result = try await self.dataManager.getProfile()
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.showLoadingIndicator = false
                        
                        if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                            if let data = result.data {
                                self.profileData = data
                                self.userProfileID = data.id ?? ""
                                self.isPrivateAccount = false
                                self.getImages()
                            }
                        } else {
                            self.errorText = result.message
                            ErrorModalManager.showErrorModal(router: self.router, errorText: self.errorText)
                        }
                    }
                } else {
                    let result = try await self.dataManager.getPublicProfile(id: self.publicProfileID)
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.showLoadingIndicator = false
                        
                        if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                            if let data = result.data {
                                self.isPrivateAccount = data.privateAccount ?? true
                                self.profileData = data
                                self.userProfileID = self.publicProfileID
                                
                                if !self.isPrivateAccount || data.isConnected ?? false {
                                    self.getImages()
                                }
                            }
                        } else {
                            self.errorText = result.message
                            ErrorModalManager.showErrorModal(router: self.router, errorText: self.errorText)
                        }
                    }
                }
                
                
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    
    func getPostData() {
        
        guard !userProfileID.isEmpty else { return }
        
        guard loadPostData else { return }
        
        guard postDataPageNo <= postDataTotalPages else { return }
        
        loadingPostData = true
        
        Task {
            do {
                let result = try await dataManager.getProfilePosts(id: userProfileID, pageNo: postDataPageNo)
                    
                await MainActor.run {
                    loadingPostData = false
                    
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            // Deduplicate posts by ID before appending
                            var existingIDs = Set(totalPostData.compactMap { $0.id })
                            let newPosts = data.filter { post in
                                if let postID = post.id {
                                    if existingIDs.contains(postID) {
                                        return false
                                    }
                                    existingIDs.insert(postID)
                                    return true
                                }
                                return false
                            }
                            
                            totalPostData += newPosts
                            loadPostData = false
                            postDataPageNo = result.pageNo ?? 1
                            postDataTotalPages = result.totalPages ?? 1
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingPostData = false
                    print(error)
                }
            }
        }
    }
    
    func refreshPost(postID: String) {
        let singlePostDataManager = SinglePostDataManager()
        
        Task {
            do {
                let result = try await singlePostDataManager.getSinglePost(id: postID)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let updatedPost = result.data {
                            // Find and update the post in totalPostData
                            if let index = totalPostData.firstIndex(where: { $0.id == postID }) {
                                // Create a new array to ensure SwiftUI detects the change
                                var updatedPosts = totalPostData
                                updatedPosts[index] = updatedPost
                                totalPostData = updatedPosts
                            } else {
                                // If post not found, it might have been removed, reload all posts
                                reloadPosts()
                            }
                        }
                    }
                }
            } catch {
                print("Failed to refresh post: \(error)")
                // On error, reload all posts as fallback
                await MainActor.run {
                    reloadPosts()
                }
            }
        }
    }
    
    func reloadPosts() {
        // Reset pagination and reload posts
        Task { @MainActor in
            totalPostData = []
            postDataPageNo = 1
            postDataTotalPages = 1
            loadPostData = true
            getPostData()
        }
    }
    
    
    func getImages() {
        guard !userProfileID.isEmpty else { return }
        
        guard loadImageData else { return }
        
        guard imageDataPageNo <= imageDataTotalPages else { return }
        
        loadingImageData = true
        
        Task {
            do {
                // First, ensure we have posts data to match media with postIDs
                if totalPostData.isEmpty {
                    // Prevent getPostData from running while we load posts
                    await MainActor.run {
                        loadPostData = false
                    }
                    
                    // Load multiple pages of posts to ensure we can match all media
                    var allPosts: [PostData] = []
                    var maxPage = 1
                    var totalPages = 1
                    
                    for page in 1...3 {
                        let postsResult = try await dataManager.getProfilePosts(id: userProfileID, pageNo: page)
                        await MainActor.run {
                            if postsResult.status && (200...204).contains(postsResult.statusCode) {
                                if let postsData = postsResult.data, !postsData.isEmpty {
                                    allPosts += postsData
                                    maxPage = postsResult.pageNo ?? page
                                    totalPages = postsResult.totalPages ?? 1
                                    print("📝 [Profile] Loaded page \(page) of posts, total posts now: \(allPosts.count)")
                                } else {
                                    // No more posts, break early
                                    if page == 1 {
                                        totalPages = 1
                                    }
                                }
                            }
                        }
                        
                        // Break early if we've loaded all pages
                        if maxPage >= totalPages {
                            break
                        }
                    }
                    
                    await MainActor.run {
                        // Deduplicate posts by ID
                        var uniquePosts: [PostData] = []
                        var seenIDs: Set<String> = []
                        
                        for post in allPosts {
                            if let postID = post.id, !seenIDs.contains(postID) {
                                seenIDs.insert(postID)
                                uniquePosts.append(post)
                            }
                        }
                        
                        totalPostData = uniquePosts
                        // Set postDataPageNo to the next page to load (maxPage + 1) or totalPages + 1 if all pages loaded
                        if maxPage < totalPages {
                            postDataPageNo = maxPage + 1
                        } else {
                            postDataPageNo = totalPages + 1
                        }
                        postDataTotalPages = totalPages
                        loadPostData = false
                        print("📝 [Profile] Deduplicated posts: \(allPosts.count) -> \(uniquePosts.count), next page: \(postDataPageNo)")
                    }
                }
                
                let result = try await dataManager.getProfilePostImages(id: userProfileID, pageNo: imageDataPageNo)
                    
                await MainActor.run {
                    loadingImageData = false
                    
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if let firstMedia = result.data?.first {
                                if photosArray.contains([firstMedia]) {
                                    loadImageData = false
                                    return
                                } else {
                                    // Populate postID from totalPostData if available
                                    var enrichedData = data
                                    print("🔍 [Profile] Enriching \(enrichedData.count) media items with postIDs from \(totalPostData.count) posts")
                                    
                                    for (index, media) in enrichedData.enumerated() {
                                        if let mediaID = media.id {
                                            // Find the post that contains this media
                                            if let post = totalPostData.first(where: { post in
                                                post.mediaRef?.contains(where: { $0.id == mediaID }) ?? false
                                            }) {
                                                enrichedData[index].postID = post.id
                                                print("✅ [Profile] Media \(mediaID) matched to post \(post.id ?? "nil")")
                                            } else {
                                                print("⚠️ [Profile] No post found for media \(mediaID)")
                                            }
                                        }
                                    }
                                    photosArray += enrichedData
                                    imageDataPageNo = result.pageNo ?? 1
                                    imageDataTotalPages = result.totalPages ?? 1
                                    loadImageData = false
                                }
                            }
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingImageData = false
                    print(error)
                }
            }
        }
    }
    
    
    func getVideos() {
        guard !userProfileID.isEmpty else { return }
        
        guard loadVideoData else { return }
        
        guard videoDataPageNo <= videoDataTotalPages else { return }
        
        loadingVideoData = true
        
        Task {
            do {
                let result = try await dataManager.getProfilePostVideos(id: userProfileID, pageNo: videoDataPageNo)
                    
                await MainActor.run {
                    loadingVideoData = false
                    
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if let firstMedia = result.data?.first {
                                if videosArray.contains([firstMedia]) {
                                    loadVideoData = false
                                    return
                                } else {
                                    videosArray += data
                                    videoDataPageNo = result.pageNo ?? 1
                                    videoDataTotalPages = result.totalPages ?? 1
                                    loadVideoData = false
                                }
                            }
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingVideoData = false
                    print(error)
                }
            }
        }
        
    }
    
    
    func getReviewsData() {
        
        guard !userProfileID.isEmpty else { return }
        
        guard loadReviewData else { return }
        
        guard reviewDataPageNo <= reviewDataTotalPages else { return }
        
        loadingReviewData = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessReviews(id: userProfileID, pageNo: reviewDataPageNo)
                    
                await MainActor.run {
                    loadingReviewData = false
                    
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            totalReviewData += data
                            loadReviewData = false
                            reviewDataPageNo = result.pageNo ?? 1
                            reviewDataTotalPages = result.totalPages ?? 1
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingReviewData = false
                    print(error)
                }
            }
        }
    }
    
    
    func followUser() {
        followButtonEnabled = false
        
        Task {
            do {
                let result = try await connectionDataManager.followUser(id: publicProfileID)
                
                await MainActor.run {
                    followButtonEnabled = true
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if data.status == "pending" {
                                profileData?.isRequested = true
                            } else if data.status == "accepted" {
                                profileData?.isRequested = false
                                profileData?.isConnected = true
                            }
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    followButtonEnabled = true
                }
                print(error)
            }
        }
    }
    
    
    func unfollowUser() {
        followButtonEnabled = false
        
        Task {
            do {
                let result = try await connectionDataManager.unFollowUser(id: publicProfileID)
                
                await MainActor.run {
                    followButtonEnabled = true
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        profileData?.isRequested = false
                        profileData?.isConnected = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    followButtonEnabled = true
                }
                print(error)
            }
        }
    }
    
    
    func getReviewProfile(placeID: String, businessProfileID: String = "") {
        
        if let businessReviewProfile {
            showCreateReviewScreen(profile: businessReviewProfile)
            return
        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await checkInDataManager.getBusinessProfile(placeID: placeID, businessProfileID: businessProfileID)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if var data = result.data {
                            data.businessProfileRef?.placeID = placeID
                            businessReviewProfile = data
                            showCreateReviewScreen(profile: data)
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    
    func blockUser() {
        Task {
            do {
                let result = try await dataManager.blockUser(id: publicProfileID)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        getProfileData()
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func redirectedToWebsite(id: String) {
        let parameters: [String: Any] = [
            "type" : "website-redirection",
            "businessProfileID" : id
        ]
        
        Task {
            do {
                let result = try await dataManager.collectData(parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                        
                    if result.status && range.contains(result.statusCode) {
                        print("Redirected to website")
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func viewedProfile(id: String) {
        let parameters: [String: Any] = [
            "type" : "account-reach",
            "businessProfileID" : id
        ]
        
        Task {
            do {
                let result = try await dataManager.collectData(parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                        
                    if result.status && range.contains(result.statusCode) {
                        print("Redirected to website")
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func reportPost(id: String) {
        Task {
            do {
                let result = try await postDataManager.reportPost(id: id)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status  && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func sharedProfile(sharedID: String, sharedByID: String) {
        Task {
            do {
                let result = try await dataManager.profileShared(sharedID: sharedID, sharedByID: sharedByID)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        print("Profile Shared Api Hit Successfully !!!")
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func reportProfile() {
        guard !publicProfileID.isEmpty else { return }
        
        Task {
            do {
                let result = try await dataManager.reportProfile(id: publicProfileID)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func deletePost(id: String, completionHandler: (() -> Void)?) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await postDataManager.deletePost(postID: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        completionHandler?()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    func removePost(id: String) {
        // Remove from posts
        if let index = totalPostData.firstIndex(where: { $0.id == id }) {
            totalPostData.remove(at: index)
        }
        
        // Remove from photos
        // Note: photosArray are MediaRef, and we enriched them with postID in getImages()
        // We filter out any media that belongs to the deleted postID
        photosArray.removeAll(where: { $0.postID == id })
        
        // Remove from videos
        videosArray.removeAll(where: { $0.postID == id })
        
        // Remove from reviews if applicable
        if let index = totalReviewData.firstIndex(where: { $0.id == id }) {
            totalReviewData.remove(at: index)
        }
    }
}
