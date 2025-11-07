//
//  BookingTableInfoViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import SwiftUI
import Combine
import SwiftfulRouting
import SSDateTimePicker


class BookingTableInfoViewModel: ObservableObject {
    
    let router: AnyRouter
    let profileData: ProfileData
    let dataManager = BookTableDataManager()
//    @Published var selectedDate: Date = Date()
    @Published var selectedTime: Time = Time()
    
    @Published var toShowAddressString: String = ""
    @Published var startDate: String = ""
    @Published var endDate: String = ""
    @Published var showTimePicker: Bool = false
    @Published var hour: Int = 0
    @Published var minutes: Int = 0
    @Published var currentPeriod: String = "AM"
    @Published var guestCount: Int = 1
    
    @Published var slots: [Slot] = []
    @Published var selectedSlot: Slot? = nil
    @Published var selectedDate: String? = nil
    @Published var showLoadingIndicator: Bool = false
    
    @Published var slotCount: Int = 0
    @Published var successMessage: String = ""
    @Published var isBookingSuccessful: Bool = false

    
    var cancellables = Set<AnyCancellable>()
    let localizationManager = LocalizationManager.shared
    
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
        $selectedTime
            .sink { [weak self] time in
                guard let self else { return }
                let components = extractTimeComponents(from: time)
                hour = components.hour
                minutes = components.minute
                currentPeriod = components.period
                
            }
            .store(in: &cancellables)
        
        
        $slots
            .sink { [weak self] slots in
                guard let self else { return }
                slotCount = slots.count
            }
            .store(in: &cancellables)
        
        $selectedDate
            .sink { [weak self] date in
                guard let self else { return }
                if let date, !date.isEmpty {
                    slots = generateSlots(for: date)
                } else {
                    slots = []
                }
                selectedSlot = nil
            }
            .store(in: &cancellables)
    }
    
    
    func extractTimeComponents(from date: Date) -> (hour: Int, minute: Int, period: String) {
        let calendar = Calendar.current
        
        let hour24 = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Convert to 12-hour format
        let hour12 = (hour24 % 12 == 0) ? 12 : hour24 % 12
        
        // Get AM/PM
        let formatter = DateFormatter()
        formatter.dateFormat = "a" // "AM" or "PM"
        let period = formatter.string(from: date)
        
        return (hour12, minute, period)
    }

    
    func generateSlots(for dateString: String) -> [Slot] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let inputDate = dateFormatter.date(from: dateString) else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if date is today or in the future
        guard inputDate >= calendar.startOfDay(for: today) else { return [] }
        
        let isToday = calendar.isDate(inputDate, inSameDayAs: today)
        let currentTime = isToday ? calendar.component(.hour, from: today) * 60 + calendar.component(.minute, from: today) : 0
        
        let timeRanges = [
            (8 * 60, 11 * 60),   // 8:00 AM - 11:00 AM
            (13 * 60, 15 * 60),  // 1:00 PM - 3:00 PM
            (19 * 60, 23 * 60)   // 7:00 PM - 11:00 PM
        ]
        
        var slots: [Slot] = []
        for range in timeRanges {
            var timeInMinutes = range.0
            while timeInMinutes < range.1 {
                if !isToday || timeInMinutes >= currentTime {
                    let hour = timeInMinutes / 60
                    let minute = timeInMinutes % 60
                    let formattedTime = String(format: "%d:%02d %@", hour % 12 == 0 ? 12 : hour % 12, minute, hour < 12 ? "AM" : "PM")
                    slots.append(Slot(time: formattedTime))
                }
                timeInMinutes += 30
            }
        }
        
        return slots
    }
    
    
    func convertTo24HourFormat(_ time12Hour: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        guard let date = dateFormatter.date(from: time12Hour) else { return nil }
        
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    
    func formatDate(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d"
        
        guard let date = dateFormatter.date(from: dateString) else { return nil }
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
}


// MARK: - Networking
extension BookingTableInfoViewModel {
    
    func bookTable() {
        guard let selectedSlot, let selectedDate else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select a time slot before proceeding.".localized(localizationManager.language))
            return
        }
        
        showLoadingIndicator = true
        Task {
            let parameters: [String: Any] = [
                "numberOfGuests": "\(guestCount)",
                "date": formatDate(selectedDate) ?? "",
                "time": convertTo24HourFormat(selectedSlot.time) ?? "",
                "businessProfileID": profileData.businessProfileID ?? ""
            ]
            
            do {
                let result = try await dataManager.bookTable(parameters: parameters)
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
