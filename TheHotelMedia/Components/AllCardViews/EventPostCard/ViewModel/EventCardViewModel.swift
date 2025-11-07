//
//  EventCardViewModel.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import Foundation
import Combine

final class EventCardViewModel: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    @Published var postType: String = ""
    @Published var data: PostData
    @Published var isPausedArray: [Bool] = []
    @Published var isPausePost: Bool = true
    @Published var previousPage: Int = 0
    @Published var isLoading: Bool = false
    @Published var accountType: String? = nil
    @Published var name: String? = nil
    @Published var location: String = ""
    @Published var shares: String = "0"
    @Published var dateAndTimeString: String = ""
    @Published var profilePic: String? = nil
    @Published var savedByMe: Bool = false
    @Published var isJoining: Bool = false
    @Published var businessAddress: String? = ""
    @Published var firstImage: String? = nil
    @Published var commentsCount: Int = 0
    @Published var comments: String = ""
    @Published var isValidEvent: Bool = true
    @Published var currentPage = 0 {
        didSet {
            previousPage = oldValue
        }
    }
    @Published var mediaContent: [MediaType] = []
    
    init(data: PostData) {
        self.data = data
        let array = mediaContent.map({ _ in return true })
        isPausedArray = array
        addSubscribers()
        print("EventCardViewModel init")
    }
    
    deinit {
        print("EventCardViewModel deinit")
    }
    
    
    func addSubscribers() {
        $currentPage
            .combineLatest($isPausePost)
            .sink { [weak self] (currentPage, isPausePost) in
                guard let self else { return }
                var array: [Bool] = []
                for i in 0..<isPausedArray.count{
                    array.append(true)
                }
                if !isPausePost, !array.isEmpty {
                    array.remove(at: currentPage)
                    array.insert(false, at: currentPage)
                }
                
                self.isPausedArray = array
            }
            .store(in: &cancellables)
        
        
        $data
            .sink { [weak self] data in
                guard let self else { return }
                accountType = data.postedBy?.accountType
                location = data.location?.placeName ?? ""
                
                if let mediaRef = data.mediaRef, !mediaRef.isEmpty {
                    var array: [MediaType] = []
                    
                    for media in mediaRef {
                        if media.mediaType == "image" {
                            firstImage = media.sourceURL
                            break
                        }
                    }
                    
                    for media in mediaRef {
                        if media.mediaType == "image" {
                            array.append(.image(urlString: media.sourceURL ?? ""))
                        } else {
                            array.append(.video(urlString: media.sourceURL ?? ""))
                        }
                    }
                    
                    mediaContent = array
                }
                
                if let shared = data.shared {
                    shares = "\(shared)"
                }
                
                if let timeString = formatTimeString(string: data.startTime ?? ""),
                   let dateString = formatDateString(string: data.startDate ?? ""){
                        dateAndTimeString = "\(dateString) at \(timeString)"
                }
                
                savedByMe = data.savedByMe ?? false
                isJoining = data.imJoining ?? false
                commentsCount = data.comments ?? 0
                
                isValidEvent = DateManager.isFutureDate(dateString: data.startDate ?? "", timeString: data.startTime ?? "")
            }
            .store(in: &cancellables)
        
        $accountType
            .sink { [weak self] type in
                guard let self else { return }
                if type == "individual" { // This is User's name and profile pic.
                    profilePic = data.postedBy?.profilePic?.small
                    name = data.postedBy?.name
                } else {
                    profilePic = data.postedBy?.businessProfileRef?.profilePic?.small
                    name = data.postedBy?.businessProfileRef?.name
                    
                    if let address = data.postedBy?.businessProfileRef?.address {
//                        if let street = address.street,
//                           let city = address.city,
                            if let state = address.state,
//                           let zipCode = address.zipCode,
                           let country = address.country {
                                location = "\(state), \(country)"
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        
        $mediaContent
            .sink { [weak self] array in
                guard let self else { return }
                
                var pauseArray: [Bool] = []
                for i in 0..<array.count {
                    pauseArray.append(true)
                }
                isPausedArray = pauseArray
            }
            .store(in: &cancellables)
        
        $commentsCount
            .sink { [weak self] count in
                guard let self else { return }
                self.comments = formatNumber(Double(count))
            }
            .store(in: &cancellables)
    }
    
    
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
    
    
    func formatTimeString(string: String) -> String? {
        let timeString = string

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm" // Input format: 24-hour time

        if let date = inputFormatter.date(from: timeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a" // Output format: 12-hour time with AM/PM
            let convertedTimeString = outputFormatter.string(from: date)
            
            return convertedTimeString
        } else {
            return nil
        }
    }
    
    
    func formatDateString(string: String) -> String? {
        let dateString = string

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd" // Input format: 2024-10-16

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "E, d MMM" // Output format: Wed, 16 Oct
            let formattedDate = outputFormatter.string(from: date)
            return formattedDate
        } else {
            return nil
        }
    }
}
