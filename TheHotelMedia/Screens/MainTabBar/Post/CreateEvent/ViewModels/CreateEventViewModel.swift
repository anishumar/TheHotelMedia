//
//  CreateEventViewModel.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import PhotosUI
import GooglePlaces
import Mantis


final class CreateEventViewModel: ObservableObject {
    
    enum EventType: String {
        case online
        case offline
    }
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    var errorMessage: String = ""
    let dataManager = EventDataManager()
    let localizationMananger = LocalizationManager.shared
    
    @Published var eventType: EventType? = nil
    @Published var eventNameFieldText: String = ""
    @Published var streamingLinkText: String = ""
    @Published var venueNameFieldText: String = ""
    @Published var placeAddress: String = ""
    @Published var longitude: Double = 0.0
    @Published var latitude: Double = 0.0
    @Published var descriptionFieldText: String = ""
    @Published var selectedStartDate: Date? = nil
    @Published var selectedEndDate: Date? = nil
    @Published var datePickerEndDate: Date = Date()
    @Published var datePickerFromDate: Date = Date()
    @Published var showStartDatePicker: Bool = false
    @Published var showEndDatePicker: Bool = false
    @Published var startDateString: String = ""
    @Published var toSendStartDate: String = ""
    @Published var toSendStartTime: String = ""
    @Published var startTimeString: String = ""
    @Published var endDateString: String = ""
    @Published var toSendEndDate: String = ""
    @Published var toSendEndTime: String = ""
    @Published var endTimeString: String = ""
    @Published var showImagePicker: Bool = false
    @Published var selectedImage: UIImage? = nil
    @Published var selectedImage2: UIImage = UIImage()
    @Published var croppedImage: UIImage? = nil
    @Published var postButtonDisabled: Bool = true
    @Published var showLoadingAnimation: Bool = false
    @Published var postUploaded: Bool = false
    @Published var showSearchScreen: Bool = false
    @Published var hightlightButton: Bool = false
    @Published var updateDatePickerBool: Bool = false
    @Published var selectedSearchPlace: GMSPlace? = nil
    @Published var showingCropper = false
    @Published var showingCropShapeList = false
    @Published var cropShapeType: Mantis.CropShapeType = .rect
    @Published var presetFixedRatioType: Mantis.PresetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 3/4)
    @Published var cropperType: ImageCropperType = .normal
    @Published var transformation: Transformation?
    var skipEndDateSelection: Bool = true
    var skipStartDateSelection: Bool = true
    var selectedOwnDate: Bool = false
    
    var onEventCreated: (() -> Void)?
    
    var pickerConfig: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .any(of: [.images])
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        return config
    }
    
    @Published var startDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endComponents = DateComponents(year: year + 1, month: month, day: day, hour: hour, minute: minute, second: second)
            return Date()
            ...
            calendar.date(from:endComponents)!
        }
        
        return Date()...Date()
    }()
    
    @Published var endDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endComponents = DateComponents(year: year + 1, month: month, day: day, hour: hour, minute: minute, second: second)
            return Date()
            ...
            calendar.date(from:endComponents)!
        }
        
        return Date()...Date()
    }()
    
    @AppStorage("newPostCreated") var newPostCreated: Bool = false
    
    init(router: AnyRouter, onEventCreated: (() -> Void)? = nil) {
        self.router = router
        self.onEventCreated = onEventCreated
        addSubscribers()
//        configureEndDate()
    }
    
    
    func addSubscribers() {
        $selectedStartDate
            .sink { [weak self] date in
                guard let self, let date else { return }
                startDateString = formatIntoDate(date: date)
                startTimeString = formatIntoTime(date: date)
                formatToSendFormat(date: date)
                updateEndDateRange(startDate: date)
                updateEndDate(startDate: date)
                updateDatePickerBool.toggle()
                
//                if !skipStartDateSelection {
//                    selectedOwnDate = true
//                }
//                
//                skipStartDateSelection = false
            }
            .store(in: &cancellables)
        
//        $datePickerEndDate
//            .sink { [weak self] date in
//                guard let self else { return }
//                if !skipEndDateSelection {
//                    selectedEndDate = date
//                }
//                skipEndDateSelection = false
//            }
//            .store(in: &cancellables)
        
        
        $selectedEndDate
            .sink { [weak self] date in
                guard let self else { return }
                if let date {
                    endDateString = formatIntoDate(date: date)
                    endTimeString = formatIntoTime(date: date)
                    formatToSendFormat(date: date, isEndDate: true)
                } else {
                    endDateString = ""
                    endTimeString = ""
                }
            }
            .store(in: &cancellables)
        
        $selectedImage
            .sink { [weak self] image in
                guard let self else { return }
                
                if let image {
                    selectedImage2 = image
                    showingCropper.toggle()
                }
                
            }
            .store(in: &cancellables)
        
        $croppedImage
            .combineLatest($eventNameFieldText)
            .map { (image, string) -> Bool in
                if image != nil && !string.isEmpty {
                    return true
                } else {
                    return false
                }
            }
            .combineLatest($eventType, $streamingLinkText, $venueNameFieldText)
            .map { [weak self] (bool, type, streamingLink, venueName) -> Bool in
                guard let self else { return false }
                
//                hightlightButton = !streamingLink.isEmpty || !venueName.isEmpty
                
                if bool && type == .offline && !venueName.isEmpty {
                    if streamingLink.isEmpty {
                        return true
                    } else if !streamingLink.isEmpty && isValidURL(streamingLink) {
                        return true
                    } else {
                        return false
                    }
                } else if bool && type == .online && !streamingLink.isEmpty && isValidURL(streamingLink) {
                    return true
                } else {
                    return false
                }
            }
            .combineLatest($descriptionFieldText, $selectedEndDate, $selectedStartDate)
            .sink { [weak self] (bool, descriptionFieldText, endDate, startDate) in
                guard let self else { return }
                
//                hightlightButton = !streamingLinkText.isEmpty
                
                postButtonDisabled = !bool || descriptionFieldText.isEmpty || endDate == nil || startDate == nil
            }
            .store(in: &cancellables)
        
        $eventNameFieldText
            .combineLatest($streamingLinkText, $venueNameFieldText, $descriptionFieldText)
            .sink { [weak self] (string1, string2, string3, string4) in
                guard let self else { return }
                
                hightlightButton = !string1.isEmpty || !string2.isEmpty || !string3.isEmpty || !string4.isEmpty
            }
            .store(in: &cancellables)
        
        $selectedSearchPlace
            .sink { [weak self] place in
                guard let self else { return }
                
                if let place {
                    let name = place.name ?? ""
                        
                        // Get the full address (formattedAddress provides a single-line formatted address)
                        let address = place.formattedAddress ?? ""
                        
                        // Get latitude and longitude
                        let latitude = place.coordinate.latitude
                        let longitude = place.coordinate.longitude
                    
                    venueNameFieldText = name
                    placeAddress = address
                    self.longitude = longitude
                    self.latitude = latitude
                    
                    print(venueNameFieldText, placeAddress, longitude, latitude)
                }
            }
            .store(in: &cancellables)
    }
    
    
    func configureEndDate() {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endDateComponents = DateComponents(year: year, month: month, day: day, hour: hour + 1, minute: minute, second: second)
            
            selectedEndDate = calendar.date(from: endDateComponents) ?? Date()
        }
    }
    
    
    func updateEndDateRange(startDate: Date) {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endComponents = DateComponents(year: year + 1, month: month, day: day, hour: hour, minute: minute, second: second)
            
            endDateRange = startDate...calendar.date(from: endComponents)!
        }
    }
    
    func updateEndDate(startDate: Date) {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endDateComponents = DateComponents(year: year, month: month, day: day, hour: hour + 1, minute: minute, second: second)
            
            self.datePickerEndDate = calendar.date(from: endDateComponents) ?? Date()
        }
        self.selectedEndDate = nil
    }

    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showCropView(image: Image) {
        router.showScreen(.fullScreenCover) { router in
            CropView(crop: .portrait, image: image, hideDismissButton: true) { [ weak self ] image, isCropped in
                guard let self else { return }
                if isCropped {
//                    croppedImage = image
                }
            }
            .environmentObject(ThemeManager.shared)
        }
    }
    
    
    func handlePickedImages(_ results: [PHPickerResult]) {
        let group = DispatchGroup()
        var newImages: [UIImage] = []
        
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    newImages.append(image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !newImages.isEmpty {
                self.selectedImage = newImages[0]
            }
        }
    }
    
    
    func formatIntoDate(date: Date) -> String {
        // Create DateFormatter
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale.current // Ensure it reflects the device's locale
        formatter.timeZone = TimeZone.current // Ensure it reflects the local time zone
        
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx"
        formatter.dateFormat = "dd MMM, yyyy"
        return formatter.string(from: date)
    }
    
    
    func formatIntoTime(date: Date) -> String {
        // Create DateFormatter
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale.current // Ensure it reflects the device's locale
        formatter.timeZone = TimeZone.current // Ensure it reflects the local time zone
        
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx"
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    
    func formatToSendFormat(date: Date, isEndDate: Bool = false) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Format for date: 2024-05-08
        let formattedDate = dateFormatter.string(from: date)
        if isEndDate {
            toSendEndDate = formattedDate
        } else {
            toSendStartDate = formattedDate
        }
        

        dateFormatter.dateFormat = "HH:mm" // Format for time: 17:00 (24-hour format)
        let formattedTime = dateFormatter.string(from: date)
        
        if isEndDate {
            toSendEndTime = formattedTime
        } else {
            toSendStartTime = formattedTime
        }

        print("Date: \(formattedDate), Time: \(formattedTime)")
    }
    
    
    func showErrorMessage() {
        if croppedImage == nil {
            errorMessage = "please_select_an_image_from_gallery".localized(localizationMananger.language)
        } else if eventNameFieldText.isEmpty {
            errorMessage = "please_enter_the_event_name".localized(localizationMananger.language)
        } else if selectedStartDate == nil {
            errorMessage = "Please select start date and start time.".localized(localizationMananger.language)
        } else if selectedEndDate == nil {
            errorMessage = "please_select_end_date_and_end_time".localized(localizationMananger.language)
        } else if eventType == nil {
            errorMessage = "please_select_an_event_type".localized(localizationMananger.language)
        } else if eventType == .online && streamingLinkText.isEmpty {
            errorMessage = "please_enter_the_streaming_link_for_the_event".localized(localizationMananger.language)
        } else if !streamingLinkText.isEmpty && !isValidURL(streamingLinkText) {
            errorMessage = "please_enter_a_valid_streaming_link".localized(localizationMananger.language)
        } else if eventType == .offline && venueNameFieldText.isEmpty {
            errorMessage = "please_select_venue_for_the_event".localized(localizationMananger.language)
        } else if descriptionFieldText.isEmpty {
            errorMessage = "please_enter_description_about_the_event".localized(localizationMananger.language)
        } else {
            errorMessage = "please_fill_all_the_required_fields".localized(localizationMananger.language)
        }
        
        ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
    }
    
    
    func isValidURL(_ urlString: String) -> Bool {
        
        let pattern = "((?:http|https)://)?(?:[\\w\\d\\-_]+\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex.firstMatch(in: urlString, options: [], range: range) != nil
        
    }
}


extension CreateEventViewModel {
    func createEvent() {
        
        showLoadingAnimation = true
        
        Task {
            var parameters: [String: Any] = [
                "name" : eventNameFieldText,
                "startDate" : toSendStartDate,
                "startTime" : toSendStartTime,
                "endDate" : toSendEndDate,
                "endTime" : toSendEndTime,
                "type" : eventType?.rawValue ?? "",
                "streamingLink" : streamingLinkText,
                "description" : descriptionFieldText,
                "venue" : "",
                "placeName" : "",
                "lat" : "",
                "lng" : "",
            ]
            
            if eventType == .offline {
                parameters.updateValue(venueNameFieldText, forKey: "venue")
                parameters.updateValue(placeAddress, forKey: "placeName")
                parameters.updateValue(latitude, forKey: "lat")
                parameters.updateValue(longitude, forKey: "lng")
            }
            
            guard let croppedImage else { return }
            
//            guard let image = await croppedImage.render(convertToColorDepth: true) else { return }
            
            do {
                let result = try await dataManager.postEvent(image: croppedImage, parameters: parameters)
                
                await MainActor.run {
                    
                    showLoadingAnimation = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        postUploaded = true
                        newPostCreated = true
                        onEventCreated?()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingAnimation = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "there_is_an_error_uploading_your_event_at_this_moment".localized(localizationMananger.language))
                }
                print(error)
            }
        }
    }
}
