//
//  MainTabBarViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import PhotosUI
import Mantis


enum ChatNavigationSource {
    case tab
    case homeShortcut
}

final class MainTabBarViewModel: ObservableObject {
    
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let homeDataManager = HomeDataManager()
    let storyDataManager = StoryDataManager()
    let notificationDataManager = NotificationDataManager()
    let localizationManager = LocalizationManager.shared
    @Published var selectedTab: TabbedItem = .home
    @Published var currentTab: TabbedItem = .home
    @Published var currentTab2: String = "Home"
    @Published var createPostOn: Bool = false
    @Published var onDoubleTap: Bool = false
    @Published var refreshHomeData: Bool = false
    @Published var hideTabBar: Bool = false
    @Published var hasSafeArea: Bool = false
    @Published var shouldPresentCamera: Bool = false
    @Published var shouldPresentImagePicker: Bool = false
    @Published var showDialogBox: Bool = false
    @Published var selectedStoryImage: Image? = nil
    @Published var selectedStoryImage2: UIImage = UIImage()
    @Published var selectedStoryVideo: URL? = nil
    @Published var trimmedStoryVideo: URL? = nil
    @Published var openCommentSection: Bool = false
    @Published var showCommentSectionSheet: Bool = false
    @Published var toNavigateScreen: NavigationScreen? = nil
    @Published var presentTab: TabbedItem = .home
    @Published var showPicker = false
    @Published var showCropView = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var hasSelectedSomeMedia: Bool = false
    @Published var isUploadingStory: Bool = false
    @Published var uploadedStory: Bool = false
    @Published var showMapOptions: Bool = false
    @Published var cropShapeType: Mantis.CropShapeType = .rect
    @Published var presetFixedRatioType: Mantis.PresetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 9/16)
    @Published var cropperType: ImageCropperType = .normal
    @Published var transformation: Transformation?
    @Published var homeScreenNavigateTo: String? = nil
    @Published var deepLink: URL? = nil
    @Published var chatNavigationSource: ChatNavigationSource = .tab
    
    var isScrolling: CurrentValueSubject<Bool, Never> = .init(false)
    var selectedLat: String = ""
    var selectedLng: String = ""
    
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("pdfLimit") var pdfLimit: Double = 5.0
    @AppStorage("videoLimit") var videoLimit: Double = 30
    @AppStorage("hasSubscription") var hasSubscription: Bool = false
    
    let socketViewModel: SocketIOViewModel = SocketIOViewModel.shared
    
    init(router: AnyRouter) {
        self.router = router
        addSubscribers()
        print("⚠️")
    }
    
    
    func addSubscribers() {
        $selectedTab.sink { [weak self] tab in
            guard let self else { return }
            if tab != currentTab {
                self.refreshHomeData = true
            }
            
            if currentTab == .home && tab != .home {
                onNavigate(bool: true)
            }
            
            if tab == .chat {
                socketViewModel.insideRecentChatEmit()
            }
            
            if currentTab == .chat, tab != .chat {
                socketViewModel.leaveRecentChatEmit()
            }
            
            self.currentTab = tab
            sendNotificationOfCurrentTab(currentTab: tab)
            
            if tab != .chat {
                chatNavigationSource = .tab
            }
        }
        .store(in: &cancellables)
        
        $selectedStoryImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    Task {
                        if let uiImage = await image.render(convertToColorDepth: true) {
                            await MainActor.run {
                                self.selectedStoryImage2 = uiImage
                                self.hasSelectedSomeMedia = false
                            }
                            
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            
                            await MainActor.run {
                                self.showCropView.toggle()
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
//        $selectedStoryImage2
//            .sink { [weak self] image in
//                guard let self else { return }
//                if let image {
//                    
//                }
//            }
//            .store(in: &cancellables)
        
        
        $createPostOn
            .combineLatest($currentTab)
            .sink { [weak self] (bool, tab) in
                guard let self else { return }
                presentTab = tab
                
                if bool {
                } else {
                    if tab == presentTab {
                    } else {
                    }
                }
                
                
            }
            .store(in: &cancellables)
        
        $photoPickerItems
            .sink { [weak self] pickerItems in
                guard let self else { return }
                
                
                Task {
                    if !pickerItems.isEmpty {
                        await MainActor.run {
                            self.hasSelectedSomeMedia = true
                        }
                        await self.parsePhotoPickerItem(pickerItems[0])
                        
                        await MainActor.run {
                            self.photoPickerItems.removeAll()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $selectedStoryVideo
            .sink { [weak self] url in
                guard let self else { return }
                if let url {
                    router.showScreen(.fullScreenCover) { router in
                        VideoEditorView(videoURL: url, limit: 30) { [weak self] editedVideoURL in
                            guard let self else { return }
                            trimmedStoryVideo = editedVideoURL
                            hasSelectedSomeMedia = false
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $trimmedStoryVideo
            .sink { [weak self] videoURL in
                guard let self else { return }
                postStory(videoURL: videoURL)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .storyUploadedFromShare)
            .sink { [weak self] _ in
                self?.uploadedStory = true
            }
            .store(in: &cancellables)
    }
    
    
    func onNavigate(bool: Bool) {
        NotificationCenter.default.post(name: .onNavigate, object: nil, userInfo: ["onNavigate" : bool])
    }
    
    
    func showCreatePostScreen() {
        router.showScreen(.push) { router in
            CreatePostScreen(viewModel: CreatePostViewModel(router: router, onPostCreated: { [weak self] in
                guard let self else { return }
                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func sendNotificationOfCurrentTab(currentTab: TabbedItem)  {
        NotificationCenter.default.post(name: .currentTab, object: currentTab)
    }
    
    
    func showCreateEventScreen() {
        router.showScreen(.push) { router in
            CreateEventScreen(viewModel: CreateEventViewModel(router: router, onEventCreated: { [weak self] in
                guard let self else { return }
                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showStoryOptionModal() {
        router.showModal(transition: .scale, dismissOnBackgroundTap: true) {
            CenterCustomModal { [weak self] in
                guard let self else { return }
                router.dismissModal()
                shouldPresentCamera.toggle()
                
            } onRightButtonPressed: { [weak self] in
                guard let self else { return }
                router.dismissModal()
                showPicker.toggle()
            }
        }
    }
    
    
    func showCreateStoryScreen(uiImage: UIImage) {
        router.showScreen(.push) { router in
            EditStoryImageView(viewModel: EditStoryImageViewModel(router: router, image: uiImage), returnedImage: { [weak self] edittedImage in
                guard let self else { return }
                postStory(image: edittedImage)
                
            }, onDismissed: {

            })
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                guard let self else { return }
                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showNotificationScreen() {
        router.showScreen(.push) { router in
            NotificationView(viewModel: NotificationViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSharedProfile(sharedID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: sharedID, sharedByProfileID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSharePostView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID, sharedByID: sharedByID), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showShareEventView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: postID, sharedByID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showLoggedInModal() {
        ErrorModalManager.showErrorModal(router: router, errorText: "You have logged in successfully.")
    }
    
    
    func navigateTo(screen: String, open: Bool) {
        NotificationCenter.default.post(name: .navigateTo, object: nil, userInfo: ["navigateTo": screen, "open" : open])
    }
    
    
    private func parsePhotoPickerItem(_ photoPickerItem: PhotosPickerItem) async {
        if photoPickerItem.isVideo {

            if let mov = try? await photoPickerItem.loadTransferable(type: VideoPickerTransferable.self) {
                await MainActor.run {
                    selectedStoryVideo = mov.url
                }
            }
            
        } else {
            guard
            let data = try? await photoPickerItem.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
            else { return }
            
            await MainActor.run {
                selectedStoryImage2 = image
                hasSelectedSomeMedia = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 ) {
                    self.showCropView.toggle()
                }
            }
        }
    }
}


// MARK: - Networking
extension MainTabBarViewModel {
    func postStory(image: UIImage? = nil, videoURL: URL? = nil) {
        
        if let image {
            let media = MediaAttachment(id: UUID().uuidString, type: .photo(image))
            
            isUploadingStory = true
            
            Task {
                do {
                    let result = try await storyDataManager.postStory(attachments: [media])
                    
                    await MainActor.run {
                        isUploadingStory = false
                        let range = 200...204
                        
                        if result.status && range.contains(result.statusCode) {
                            uploadedStory = true
                        } else {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        isUploadingStory = false
                        let errorMessage = getStoryUploadErrorMessage(from: error)
                        ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                    }
                }
            }
        } else if let videoURL {
            let media = MediaAttachment(id: UUID().uuidString, type: .video(UIImage(), videoURL))
            
            isUploadingStory = true
            
            Task {
                do {
                    let result = try await storyDataManager.postStory(attachments: [media])
                    
                    await MainActor.run {
                        isUploadingStory = false
                        let range = 200...204
                        
                        if result.status && range.contains(result.statusCode) {
                            uploadedStory = true
                        } else {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        isUploadingStory = false
                        let errorMessage = getStoryUploadErrorMessage(from: error)
                        ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                    }
                }
            }
        }
    }
    
    private func getStoryUploadErrorMessage(from error: Error) -> String {
        // Check for timeout errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                // Use existing error message with timeout context
                return "The upload timed out. Please check your connection and try again."
            case .notConnectedToInternet:
                return "no_internet_connection".localized(localizationManager.language)
            case .networkConnectionLost:
                return "The network connection was lost. Please try again."
            default:
                break
            }
        }
        
        // Check for NSError with NSURLErrorDomain
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "The upload timed out. Please check your connection and try again."
            case NSURLErrorNotConnectedToInternet:
                return "no_internet_connection".localized(localizationManager.language)
            case NSURLErrorNetworkConnectionLost:
                return "The network connection was lost. Please try again."
            default:
                break
            }
        }
        
        // Check for NetworkError
        if let networkError = error as? NetworkError {
            if case .invalidServerResponse(let message) = networkError, let msg = message {
                return msg
            }
        }
        
        // Default error message
        return "an_error_occured_while_uploading_the_story".localized(localizationManager.language)
    }
    
    
    func checkNotificationStatus() {
        Task {
            let result = try await notificationDataManager.getNotificationStatus()
            
            await MainActor.run {
                let range = 200...204
                
                if result.status && range.contains(result.statusCode) {
                    if let data = result.data {
                        if let notifications = data.notifications,
                           let hasUnreadMessages = notifications.hasUnreadMessages {
                            hasReadNotifcation = !hasUnreadMessages
                        }
                        
                        if let messages = data.messages,
                           let hasUnreadMessages = messages.hasUnreadMessages {
                            hasReadChat = !hasUnreadMessages
                        }
                    }
                }
            }
        }
    }
    
    
    func getSubscriptionMeta() {
        Task {
            let result = try await homeDataManager.getSubscriptionMeta()
            
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


extension Notification.Name {
    static let currentTab = Notification.Name("CurrentTab")
    static let isScrolling = Notification.Name("isScrolling")
    static let navigateTo = Notification.Name("navigateTo")
}
