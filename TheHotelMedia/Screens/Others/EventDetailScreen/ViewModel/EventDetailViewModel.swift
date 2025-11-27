//
//  EventDetailViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 07/11/24.
//

import SwiftfulRouting
import SwiftUI
import Combine
import CoreLocation


class EventDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let postID: String
    let dataManager = EventDetailDataManager()
    let singlePostDataManager = SinglePostDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var eventPost: PostData? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var joiningPeople: [JoinProfileRef] = []
    @Published var fullDescription: String = ""
    @Published var description: String = ""
    @Published var isExpanded: Bool = false
    @Published var attributedDescription: AttributedString = ""
    @Published var offlineEvent: Bool = false
    @Published var currentLatitude: Double = 0.0
    @Published var currentLongitude: Double = 0.0
    @Published var eventLatitude: Double = 0.0
    @Published var eventLongitude: Double = 0.0
    @Published var eventDistance: Double = 0
    @Published var startDate: String = ""
    @Published var endDate: String = ""
    @Published var startTime: String = ""
    @Published var endTime: String = ""
    @Published var isSameDate: Bool = true
    @Published var imJoining: Bool = true
    @Published var savedByMe: Bool = false
    @Published var businessAddress: String = ""
    @Published var eventLocation2DCoordinates: CLLocationCoordinate2D? = nil
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    @Published var isSharePresented: Bool = false
    @Published var sharePostData: PostData? = nil
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var showPreview: Bool = false
    @Published var isValidEvent: Bool = false
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    let localizationManager = LocalizationManager.shared
    
    var isLongDescription: Bool = false
    
    init(router: AnyRouter, postID: String, sharedByID: String = "") {
        self.router = router
        self.postID = postID
        addSubscribers()
        
        if !sharedByID.isEmpty {
            if let encryptedPostID = EncryptionHelper.encrypt(postID),
               let encryptedUserID = EncryptionHelper.encrypt(sharedByID) {
                
                sharedEvent(postID: encryptedPostID, sharedByID: encryptedUserID)
            }
            
        }
        
    }
    
    
    func addSubscribers() {
        $eventPost
            .sink { [weak self] data in
                guard let self else { return }
                
                if let data {
                    
                    imJoining = data.imJoining ?? false
                    savedByMe = data.savedByMe ?? false
                    
                    if let address = data.postedBy?.businessProfileRef?.address,
                       let street = address.street,
                       let city = address.city,
                       let state = address.state,
                       let zipCode = address.zipCode,
                       let country = address.country {
                        
                        businessAddress = "\(street), \(city), \(state), \(zipCode), \(country)"
                    }
                       
                    
                    if let joiningPeople = data.eventJoinsRef {
                        let count = joiningPeople.count
                        var array: [JoinProfileRef] = []
                        if count <= 6 {
                            array = joiningPeople
                        } else {
                            array = Array(joiningPeople[0..<6])
                        }
                        
                        self.joiningPeople = array
                    }
                    
                    fullDescription = data.content ?? ""
                    isLongDescription = fullDescription.count > 160
                    getAttributedDescription(id: data.id ?? "")
                    
                    offlineEvent = data.type == "offline"
                    
                    if let location = data.location,
                       let lat = location.lat,
                       let lng = location.lng {
                        
                        eventLatitude = lat
                        eventLongitude = lng
                    }
                    
                    startDate = convertDateToCustomFormat(dateString: data.startDate ?? "") ?? ""
                    endDate = convertDateToCustomFormat(dateString: data.endDate ?? "") ?? ""
                    startTime = convertTo12HourFormat(time: data.startTime ?? "") ?? ""
                    endTime = convertTo12HourFormat(time: data.endTime ?? "") ?? ""
                    
                    isValidEvent = DateManager.isFutureDate(dateString: data.startDate ?? "", timeString: data.startTime ?? "")
                    
                    isSameDate = startDate == endDate
                }
            }
            .store(in: &cancellables)
        
        $currentLatitude
            .combineLatest($currentLongitude, $eventLatitude, $eventLongitude)
            .sink { [weak self] (lat1, lng1, lat2, lng2) in
                guard let self else { return }
                print(lat1, lng1, lat2, lng2)
                
                eventDistance = distanceBetweenCoordinates(lat1: lat1, lng1: lng1, lat2: lat2, lng2: lng2)
                eventLocation2DCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat2), longitude: CLLocationDegrees(lng2))
            }
            .store(in: &cancellables)
    }
    
    
    func distanceBetweenCoordinates(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lng1)
        let location2 = CLLocation(latitude: lat2, longitude: lng2)
        
        // Returns distance in meters
        let distanceInMeters = location1.distance(from: location2)
        print(distanceInMeters)
        return distanceInMeters/1000
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
//    func getAttributedDescription() {
//        var string = AttributedString(fullDescription)
//        if isLongDescription {
//            
//            if !isExpanded {
//                string = AttributedString(fullDescription.prefix(160))
//            }
//            
//            var tappableText = AttributedString("...Read less".localized(localizationManager.language))
//            
//            if !isExpanded {
//                tappableText = AttributedString("...Read more".localized(localizationManager.language))
//            }
//            
//            tappableText.link = URL(string: "readmore://")
//            tappableText.foregroundColor = .hmIndigo
//
//            string.append(tappableText)
//        }
//        
//        attributedDescription = string
//        
//    }
    
//    func getAttributedDescription(id: String) {
//        var string = AttributedString(fullDescription)
//        
//        // Regular expression for URLs
//        let urlRegex = try! NSRegularExpression(pattern: "(https?://[a-zA-Z0-9._%+-]+\\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9._%+-]*)*(?:\\?[a-zA-Z0-9&=_%+-]*)?)", options: [])
//        let matches = urlRegex.matches(in: fullDescription, options: [], range: NSRange(fullDescription.startIndex..., in: fullDescription))
//        
//        // Add tappable links for URLs
//        for match in matches {
//            guard let rangeInString = Range(match.range, in: fullDescription) else {
//                continue
//            }
//            let urlText = String(fullDescription[rangeInString])
//            let link = URL(string: "link://\(id)?url=\(urlText)")!
//            
//            // Convert the matched substring to an attributed string
//            var attributedSubstring = AttributedString(urlText)
//            attributedSubstring.link = link
//            attributedSubstring.foregroundColor = .hmIndigo
//            attributedSubstring.underlineStyle = .single
//            
//            // Replace the matched range in the original AttributedString
//            if let rangeInAttributedString = Range(match.range, in: string) {
//                string.replaceSubrange(rangeInAttributedString, with: attributedSubstring)
//            }
//        }
//        
//        // Handle Read More / Read Less
//        if isLongDescription {
//            var tappableText = AttributedString("...Read less".localized(localizationManager.language))
//            
//            if !isExpanded {
//                tappableText = AttributedString("...Read more".localized(localizationManager.language))
//            }
//            
//            tappableText.link = URL(string: "readmore://")
//            tappableText.foregroundColor = .hmIndigo
//            
//            string.append(tappableText)
//        }
//        
//        attributedDescription = string
//    }
//
    func getAttributedDescription(id: String) {
        let isContentLong = fullDescription.count > 160
        let truncatedContent = isContentLong ? String(fullDescription.prefix(160)) : fullDescription
        var attributedString = AttributedString(isExpanded ? fullDescription : truncatedContent)
        
        // Regular expression for URLs
        let urlRegex = try! NSRegularExpression(pattern: "(https?://[a-zA-Z0-9._%+-]+\\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9._%+-]*)*(?:\\?[a-zA-Z0-9&=_%+-]*)?)", options: [])
        let matches = urlRegex.matches(in: fullDescription, options: [], range: NSRange(fullDescription.startIndex..., in: fullDescription))
        
        // Add tappable links for URLs
        for match in matches {
            guard let rangeInString = Range(match.range, in: fullDescription),
                  let rangeInAttributedString = Range(match.range, in: attributedString) else {
                continue
            }
            let urlText = String(fullDescription[rangeInString])
            let link = URL(string: "link://\("tabbar")?url=\(urlText)")!
            
            attributedString[rangeInAttributedString].link = link
            attributedString[rangeInAttributedString].foregroundColor = .hmIndigo
            attributedString[rangeInAttributedString].underlineStyle = .single
        }
        
        
        
        // Append Read More/Read Less
        if isContentLong {
            let readMoreOrLessText = isExpanded ? "...Read less" : "...Read more"
            appendTappableText(&attributedString, text: readMoreOrLessText, link: "readmore://\(id)")
        }
        
        attributedDescription = attributedString
    }
    
    
    private func appendTappableText(_ attributedString: inout AttributedString, text: String, link: String) {
        var tappableText = AttributedString(text)
        tappableText.link = URL(string: link)
        tappableText.foregroundColor = .hmIndigo
        tappableText.font = .custom(Constants.comicFont, size: 13.2)
        attributedString.append(tappableText)
    }
    
    
    
    func showShareView(id: String) {
        sharePostData = eventPost
        let baseURLString = "https://thehotelmedia.com/share/events"
        
        if !id.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedID = EncryptionHelper.encrypt(id),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented = true
            }
        }
    }
    
    
    func convertTo12HourFormat(time: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm" // Input format: 24-hour time
        
        // Convert to Date object
        if let date = dateFormatter.date(from: time) {
            // Set output format to 12-hour with AM/PM
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        
        return nil
    }
    
    
    func convertDateToCustomFormat(dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd" // Input format
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "E, d MMM yyyy" // Desired output format
            return outputFormatter.string(from: date)
        }
        
        return nil
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
    
}

// MARK: -  Networking

extension EventDetailViewModel {
    
    func getEvent(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getSinglePost(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            eventPost = data
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
    
    
    func joinEvent(id: String) {
        Task {
            do {
                let _ = try await dataManager.joinEvent(postID: id)
            } catch {
                print(error)
            }
        }
    }
    
    
    func saveAPost(id: String) {
        Task {
            do {
                let _ = try await dataManager.saveAPost(postID: id)
            } catch {
                print(error)
            }
        }
    }
    
    
    func sharedEvent(postID: String, sharedByID: String) {
        Task {
            do {
                let _ = try await singlePostDataManager.postShared(postID: postID, sharedByID: sharedByID)
                
            } catch {
                print(error)
            }
        }
    }
}
