//
//  BookingBanquetInfoViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 26/03/25.
//

import Foundation
import SwiftfulRouting
import Combine


class BookingBanquetInfoViewModel: ObservableObject {
    
    let router: AnyRouter
    let profileData: ProfileData
    let dataManager = BookBanquetDataManager()
    let localizationManager = LocalizationManager.shared
    var cancellables = Set<AnyCancellable>()
    @Published var toShowAddressString: String = ""
    @Published var eventTypes: [String] = [
        "Birthday Party",
        "Wedding Ceremony",
        "Anniversary Celebration",
        "Corporate Event",
        "Baby Shower",
        "Engagement Party",
        "Farewell Party",
        "Reunion",
        "Festival Celebration",
        "Charity Event",
        "Other Occasion"
    ]
    
    @Published var selectedType: String = ""
    @Published var fromDateString: String = "From"
    @Published var toDateString: String = "To"
    @Published var selectedFromDate: Date? = nil
    @Published var selectedToDate: Date? = nil
    @Published var pickerFromDate: Date = Date()
    @Published var pickerToDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    @Published var showFromDatePicker: Bool = false
    @Published var showToDatePicker: Bool = false
    @Published var updateDatePickerBool: Bool = false
    @Published var skipFromDate: Bool = true
    @Published var skipToDate: Bool = true
    @Published var showLoadingIndicator: Bool = false
    @Published var otherOccasionFieldText: String = ""
    var selectedGuestCountRange: String = ""
    
    @Published var successMessage: String = ""
    @Published var isBookingSuccessful: Bool = false
    
    @Published var fromDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endComponents = DateComponents(year: year, month: month + 6, day: day, hour: hour, minute: minute, second: second)
            return Date()
            ...
            calendar.date(from:endComponents)!
        }
        
        return Date()...Date()
    }()
    
    @Published var toDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second,
           let initialdate = calendar.date(byAdding: .day, value: 1, to: Date()){
            
            
            let endComponents = DateComponents(year: year, month: month, day: day + 15, hour: hour, minute: minute, second: second)
            return initialdate
            ...
            calendar.date(from:endComponents)!
        }
        
        return Date()...Date()
    }()
    
    init(router: AnyRouter, profileData: ProfileData) {
        self.router = router
        self.profileData = profileData
        addSubscribers()
        if let address = profileData.businessProfileRef?.address {
            var addressString = ""
            if let street = address.street {
                addressString.append("\(street)")
            }
            
            if let city = address.city {
                addressString.append(", \(city)")
            }
            
            if let state = address.state {
                addressString.append(", \(state)")
            }
            
            if let zipCode = address.zipCode {
                addressString.append(", \(zipCode)")
            }
            
            if let country = address.country {
                addressString.append(", \(country)")
            }
            
            toShowAddressString = addressString
        }
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func addSubscribers() {
//        $pickerFromDate
//            .sink { [weak self] date in
//                guard let self else { return }
//                if !skipFromDate {
//                    selectedFromDate = date
//                }
//                skipFromDate = false
//            }
//            .store(in: &cancellables)
//        
//        $pickerToDate
//            .sink { [weak self] date in
//                guard let self else { return }
//                if !skipToDate {
//                    selectedToDate = date
//                }
//                skipToDate = false
//            }
//            .store(in: &cancellables)
        
        $selectedFromDate
            .sink {[weak self] date in
                guard let self, let date else { return }
                fromDateString = formatIntoDate(date: date)
                updateEndDateRange(startDate: date)
                updateToDate(startDate: date)
                updateDatePickerBool.toggle()
            }
            .store(in: &cancellables)
        
        $selectedToDate
            .sink { [weak self] date in
                guard let self, let date else { return }
                toDateString = formatIntoDate(date: date)
            }
            .store(in: &cancellables)
    }
}


// MARK: - Helper Methods
extension BookingBanquetInfoViewModel {
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
    
    
    func updateToDate(startDate: Date) {
        selectedToDate = nil
        toDateString = "To"
    }
    
    
    func updateEndDateRange(startDate: Date) {
        let calendar = Calendar.current
        
        if let initialDate = calendar.date(byAdding: .day, value: 1, to: startDate),
           let lastDate = calendar.date(byAdding: .day, value: 15, to: startDate) {
            toDateRange = initialDate...lastDate
            pickerToDate = initialDate
        }
    }
    
    
    func formatToSendFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Format for date: 2024-05-08
        let formattedDate = dateFormatter.string(from: date)
         
        return formattedDate
    }
    
    
    func extractUpperLimit(from range: String) -> Int? {
        if range.contains("+") {
            return Int(range.replacingOccurrences(of: "+", with: ""))
        } else if let upperLimit = range.split(separator: "-").last?.trimmingCharacters(in: .whitespaces),
                  let upperValue = Int(upperLimit) {
            return upperValue
        }
        return nil
    }
}

// MARK: - Networking
extension BookingBanquetInfoViewModel {
    
    func bookBanquet() {
        guard !selectedType.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select an event type.".localized(localizationManager.language))
            return
        }
        
        var eventType = ""
        
        if selectedType == "Other Occasion" {
            guard !otherOccasionFieldText.isEmpty else {
                ErrorModalManager.showErrorModal(router: router, errorText: "Please enter other event name in the field.".localized(localizationManager.language))
                return
            }
            eventType = otherOccasionFieldText
        } else {
            eventType = selectedType
        }
        
        
        guard let selectedToDate, let selectedFromDate else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select check-in/check-out dates.".localized(localizationManager.language))
            return
        }
        
        guard !selectedGuestCountRange.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select number of guests.".localized(localizationManager.language))
            return
        }
        
        showLoadingIndicator = true
        
        Task {
            let parameters: [String: Any] = [
                "checkIn": DateManager.formatDateToyyyyMMdd(selectedFromDate),
                "checkOut": DateManager.formatDateToyyyyMMdd(selectedToDate),
                "businessProfileID": profileData.businessProfileID ?? "",
                "numberOfGuests": "\(extractUpperLimit(from: selectedGuestCountRange) ?? 0)",
                "typeOfEvent": eventType,
            ]
            
            do {
                let result = try await dataManager.bookBanquet(parameters: parameters)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        successMessage = result.message
                        isBookingSuccessful = true
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
//                    if result.status && range.contains(result.statusCode) {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//                            guard let self else { return }
//                            dismissScreen()
//                        }
//                    }
                }
                
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
}
