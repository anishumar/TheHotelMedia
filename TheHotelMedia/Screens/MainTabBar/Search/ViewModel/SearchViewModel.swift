//
//  SearchViewModel.swift
//  HotelMedia
//
//  Created by MAC on 14/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import GooglePlaces

enum PostType: String {
    case profile = "Users"
    case post = "Posts"
    case event = "Events"
    case review = "Reviews"
    case business = "Nearby"
}

final class SearchViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = SearchDataManager()
    let postDataManager = PostDataManager()
    let profileDataManager = ProfileDataManager()
    let businessTypeDataManager = BusinessTypeDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var searchFieldText: String = ""
    @Published var radius: Double = 50
    @Published var selectedType: PostType = .business
    @Published var showSearchTabView: Bool = false
    @Published var showSearchFilterView: Bool = false
    @Published var showPlaceSearch: Bool = false
    @Published var selectedPlace: GMSPlace? = nil
    @Published var profileResults: [String] = []
    @Published var businessTypes: [TypeModel] = []
    @Published var selectedBusinessType: TypeModel? = nil
    @Published var selectedBusinessTypes: [TypeModel] = []
    @Published var appliedBusinessType: TypeModel? = nil
    
    @Published var selectedAddress: Address? = nil
    @Published var addressString: String = ""
    var currentAddressString: String = ""
    @Published var postResults: [String] = []
    @Published var eventResults: [String] = []
    @Published var reviewResults: [String] = []
    @Published var mostlySearched: [String] = [
        "Maple Leaf Hotel",
        "CP 67",
        "Pyramid Microberry | Café | Lounge | Bar Mohali",
        "TDI Club Retreat",
        "Grand Imperial, Shibzada Ajit Singh Nagar",
    ]
    
    @Published var profilesCount: Int = 0
    @Published var searchProfileData: [SearchProfileData] = []
    @Published var profileDataPageNo: Int = 1
    @Published var profileDataTotalPages: Int = 1
    
    @Published var nearbyProfilesCount: Int = 0
    @Published var nearbyProfileData: [SearchProfileData] = []
    @Published var nearbyDataPageNo: Int = 1
    @Published var nearbyDataTotalPages: Int = 1
    
    @Published var searchPostData: [PostData] = []
    @Published var postDataPageNo: Int = 1
    @Published var postDataTotalPages: Int = 1
    
    @Published var searchEventData: [PostData] = []
    @Published var eventDataPageNo: Int = 1
    @Published var eventDataTotalPages: Int = 1
    
    @Published var searchReviewData: [PostData] = []
    @Published var reviewDataPageNo: Int = 1
    @Published var reviewDataTotalPages: Int = 1
    
    @Published var showPostOptionView: Bool = false
    @Published var postOptionYOffset: CGFloat = 0
    var yOffsetArrayOfProfiles: [CGFloat] = []
    var yOffsetArrayOfNearbyProfiles: [CGFloat] = []
    
    @Published var reportType: String = "user"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    @Published var showLoadingIndicator: Bool = false
    var recentQuery: String = ""
    var lastSelectedType: PostType = .profile
    
    var isChangingLocationDirectly: Bool = false
    var refreshOnAppear: Bool = true
    
    var currentCoordinate: CLLocationCoordinate2D? = nil
    @Published var selectedCoordinates: CLLocationCoordinate2D? = nil
    
    var locationCancellable: AnyCancellable? = nil
    private var searchDataTask: Task<Void, Never>?
    
    var locationManager = LocationManager()
    
    init(router: AnyRouter) {
        self.router = router
        addSubscribers()
        getBusinessTypes()
//        locationManager.requestLocation()
        locationManager.requestLocationPermission()
        showLoadingIndicator = true
    }
    
    
    private func addSubscribers() {        
        $searchFieldText
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                
                guard recentQuery != query else { return }
                recentQuery = query
                
                switch selectedType {
                case .profile:
                    searchProfileData.removeAll()
                case .post:
                    searchPostData.removeAll()
                case .event:
                    searchEventData.removeAll()
                case .review:
                    searchReviewData.removeAll()
                case .business:
                    nearbyProfileData.removeAll()
                }
                
                switch selectedType {
                case .profile:
                    profileDataPageNo = 1
                    getSearchResult(type: .profile, query: query, resetData: true)
                case .post:
                    postDataPageNo = 1
                    getSearchResult(type: .post, query: query, resetData: true)
                case .event:
                    eventDataPageNo = 1
                    getSearchResult(type: .event, query: query, resetData: true)
                case .review:
                    reviewDataPageNo = 1
                    getSearchResult(type: .review, query: query, resetData: true)
                case .business:
                    nearbyDataPageNo = 1
                    getSearchResult(type: .business, query: query, resetData: true)
                }
                
            }
            .store(in: &cancellables)
        
        
        $selectedPlace
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    selectedCoordinates = place.coordinate
                }
            }
            .store(in: &cancellables)
        
        $selectedAddress
            .sink { [weak self] address in
                guard let self else { return }
                if let address {
                    var locationString = ""
                    if let street = address.street {
                        locationString.append("\(street), ")
                    }
                    
                    if let city = address.city {
                        locationString.append("\(city), ")
                    }
                    
                    if let state = address.state {
                        locationString.append("\(state), ")
                    }
                    
                    if let zipCode = address.zipCode {
                        locationString.append("\(zipCode), ")
                    }
                    
                    if let country = address.country {
                        locationString.append("\(country)")
                    }
                    
                    addressString = locationString
                    if selectedCoordinates == currentCoordinate {
                        currentAddressString = locationString
                    }
                }
            }
            .store(in: &cancellables)
        
        locationCancellable = locationManager.$currentLocation
            .sink { [weak self] location in
                guard let self else { return }
                if let location {
                    currentCoordinate = location
                    selectedCoordinates = location
                    getSearchResult(type: selectedType, resetData: true)
                    locationCancellable = nil
                } else {
                    showLoadingIndicator = false
                }
            }
//            .store(in: &cancellables)
        
        $selectedCoordinates
            .sink { [weak self] coordinates in
                guard let self else { return }
                
                if let coordinates {
                    locationManager.fetchAddressFromCoordinates(coordinates: coordinates) { address in
                        self.selectedAddress = address
                    }
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
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEventDetailScreen(id: String) {
        router.showScreen(.push) { routeer in
            EventDetailView(viewModel: EventDetailViewModel(router: routeer, postID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func resetArrays() {
        searchProfileData.removeAll()
        searchPostData.removeAll()
        searchEventData.removeAll()
        searchReviewData.removeAll()
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
    
}

// MARK: - Cancelling Data Task
extension SearchViewModel {
    func cancelSearchDataTask() {
        showLoadingIndicator = false
        searchDataTask?.cancel()
        searchDataTask = nil
    }
}


// MARK: - Networking
extension SearchViewModel {
    func getSearchResult(type: PostType, query: String = "", resetData: Bool = false) {
        
        if type == .profile {
            getProfileResults(query: query, resetData: resetData)
        } else if type == .business {
            getProfileResults(query: query, resetData: resetData, isnearby: true)
        } else {
            getPostResults(type: type, query: query, resetData: resetData)
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
    
    
    func getProfileResults(query: String, resetData: Bool, isnearby: Bool = false) {
        if isnearby {
            guard nearbyDataPageNo <= nearbyDataTotalPages else { return }
        } else {
            guard profileDataPageNo <= profileDataTotalPages else { return }
        }
        
        var lat: Double? = 23.4733
        var lng: Double? = 80.0110
        
        if let selectedCoordinates, query.isEmpty {
            lat = selectedCoordinates.latitude.magnitude
            lng = selectedCoordinates.longitude.magnitude
            
        } else if !query.isEmpty {
            lat = nil
            lng = nil
        }
        
        showLoadingIndicator = true
        
        searchDataTask?.cancel()
        searchDataTask = Task {
            do {
                let result = try await dataManager.getSearchProfileResults(query: query, pageNo: isnearby ? nearbyDataPageNo : profileDataPageNo, selectedTypes: selectedBusinessTypes, isnearby: isnearby, lat: lat, lng: lng, radius: radius)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            var offsetArray: [CGFloat] = []
                            if resetData {
                                for _ in data {
                                    offsetArray.append(0)
                                }
                                if isnearby {
                                    nearbyProfilesCount = data.count
                                    yOffsetArrayOfNearbyProfiles = offsetArray
                                    nearbyProfileData = data
                                } else {
                                    profilesCount = data.count
                                    yOffsetArrayOfProfiles = offsetArray
                                    searchProfileData = data
                                }
                                
                                
                            } else {
                                for _ in data {
                                    offsetArray.append(0)
                                }
                                
                                if isnearby {
                                    nearbyProfilesCount += data.count
                                    yOffsetArrayOfNearbyProfiles += offsetArray
                                    nearbyProfileData += data
                                } else {
                                    profilesCount += data.count
                                    yOffsetArrayOfProfiles += offsetArray
                                    searchProfileData += data
                                }
                                
                                
                            }
                            
                        }
                        if isnearby {
                            nearbyDataPageNo = result.pageNo ?? 1
                            nearbyDataTotalPages = result.totalPages ?? 1
                        } else {
                            profileDataPageNo = result.pageNo ?? 1
                            profileDataTotalPages = result.totalPages ?? 1
                        }
                        
                        
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
//    func reportProfile(id: String) {
//        Task {
//            do {
//                let result = try await profileDataManager.reportProfile(id: id)
//                
//                await MainActor.run {
//                    let range = 200...204
//                    if result.status && range.contains(result.statusCode) {
//                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
//                    }
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
    
    func getBusinessTypes() {
        Task {
            do {
                let result = try await businessTypeDataManager.getBusinessType()
                
                await MainActor.run {
                    if let data = result.data {
                        businessTypes = data
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func getPostResults(type: PostType, query: String, resetData: Bool) {
        
        var lat: Double? = 0.0
        var lng: Double? = 0.0
        
        if let selectedCoordinates, query.isEmpty {
            lat = selectedCoordinates.latitude.magnitude
            lng = selectedCoordinates.longitude.magnitude
        }
        
        searchDataTask?.cancel()
        searchDataTask = Task {
            var pageNo: Int = 1
            
            if type == .post {
                guard postDataPageNo <= postDataTotalPages else { return }
                pageNo = postDataPageNo
            } else if type == .event {
                guard eventDataPageNo <= eventDataTotalPages else { return }
                pageNo = eventDataPageNo
            } else if type == .review {
                guard reviewDataPageNo <= reviewDataTotalPages else { return }
                pageNo = reviewDataPageNo
            } else {
                return
            }
            
            await MainActor.run {
                showLoadingIndicator = true
            }
            
            do {
                let result = try await dataManager.getSearchPostResults(query: query, type: type.rawValue.lowercased(), pageNo: pageNo, selectedTypes: selectedBusinessTypes, lat: lat, lng: lng, radius: radius)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if resetData {
                                switch type {
                                case .profile:
                                    break
                                case .post:
                                    searchPostData = data
                                case .event:
                                    searchEventData = data
                                case .review:
                                    searchReviewData = data
                                case .business:
                                    break
                                }
                                
                            } else {
                                switch type {
                                case .profile:
                                    break
                                case .post:
                                    searchPostData += data
                                case .event:
                                    searchEventData += data
                                case .review:
                                    searchReviewData += data
                                case .business:
                                    break
                                }
                            }
                            
                        }
                        
                        switch type {
                        case .profile:
                            break
                        case .post:
                            postDataPageNo = result.pageNo ?? 1
                            postDataTotalPages = result.totalPages ?? 1
                        case .event:
                            eventDataPageNo = result.pageNo ?? 1
                            eventDataTotalPages = result.totalPages ?? 1
                        case .review:
                            reviewDataPageNo = result.pageNo ?? 1
                            reviewDataTotalPages = result.totalPages ?? 1
                        case .business:
                            break
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
        
    }
}
