//
//  InsightViewModel.swift
//  HotelMedia
//
//  Created by MAC on 12/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class InsightViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = InsightDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var startDate: String = ""
    @Published var endDate: String = ""
    @Published var selectedType: CalendarType = .year
    @Published var insightData: InsightData? = nil
    @Published var chartData: ChartData? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var refreshData: Bool = false
    @Published var stories: [MyStory] = []
    @Published var mediaRefArray: [MediaRef] = []
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var showPreview: Bool = false
    
    private var insightDataTask: Task<Void, Never>?
    
    init(router: AnyRouter) {
        self.router = router
        addSubcribers()
    }
    
    
    private func addSubcribers() {
        
        $insightData
            .sink { [weak self] data in
                guard let self else { return }
                if let data {
                    chartData = data.data
                    
                    if let stories = data.stories {
                        self.stories = stories
                    }
                    
                    var mediaArray: [MediaRef] = []
                    
                    if let posts = data.posts {
                        for post in posts {
                            if var mediaRef = post.mediaRef, !mediaRef.isEmpty {
                                mediaRef[0].postID = post.id
                                mediaRef[0].postType = post.postType
                                mediaArray.append(mediaRef[0])
                            }
                        }
                    }
                    
                    self.mediaRefArray = mediaArray
                }
            }
            .store(in: &cancellables)
        
        $startDate
            .sink { [weak self] (startDate)  in
                guard let self else { return }
                if selectedType == .week || selectedType == .year {
                    print(startDate)
                } else {
                    print(startDate, endDate)
                }
            }
            .store(in: &cancellables)
        
        $selectedType
            .sink { [weak self] type in
                guard let self else { return }
                switch type {
                case .week:
                    getInsightData(filter: "weekly")
                case .month:
                    getInsightData(filter: "monthly")
                case .year:
                    getInsightData(filter: "yearly")
                }
            }
            .store(in: &cancellables)
    }
    
    
    func showNotificationScreen() {
        router.showScreen(.push) { router in
            NotificationView(viewModel: NotificationViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
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
    
    
    func showPostScreen(postID: String) {
        router.showScreen(.push) { router in
            SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEventDetailScreen(eventID: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: eventID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
//    func generateImage(media: MediaRef) async -> MediaRef? {
//        var newMedia = media
//        
//        guard media.mediaType == "video" else { return nil }
//        
//        if let image = try? await URL(string: media.sourceURL ?? "")!.generateVideoThumbnail() {
//           newMedia.videoThumbnail = image
//            return newMedia
//        } else {
//            return nil
//        }
//    }
    
    func generateImage(videoURL: URL) async -> UIImage? {
        if let image = try? await videoURL.generateVideoThumbnail() {
           return image
        } else {
            return nil
        }
    }
}

// MARK: - Cancelling Data Tasks
extension InsightViewModel {
    func cancelInsightDataTask() {
        insightDataTask?.cancel()
        insightDataTask = nil
    }
}



// MARK: - Networking
extension InsightViewModel {
    
    func getInsightData(filter: String) {
//        showLoadingIndicator = true
        
        insightDataTask?.cancel()
        insightDataTask = Task {
            do {
                let result = try await dataManager.getInsightData(filter: filter)
                
                await MainActor.run {
//                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            insightData = data
                            refreshData.toggle()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
//                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
}
