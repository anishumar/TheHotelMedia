//
//  BookingInfoViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import Foundation
import Combine
import SwiftfulRouting


class BookingInfoViewModel: ObservableObject {
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    @Published var profileData: ProfileData? = nil
    @Published var selectedFromDate: Date? = nil
    @Published var selectedToDate: Date? = nil
    @Published var pickerFromDate: Date = Date()
    @Published var pickerToDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    @Published var fromDateString: String = "From"
    @Published var toDateString: String = "To"
    @Published var guestFieldText: String = ""
    @Published var toShowAddressString: String = ""
    @Published var showFromDatePicker: Bool = false
    @Published var showToDatePicker: Bool = false
    @Published var updateDatePickerBool: Bool = false
    @Published var skipFromDate: Bool = true
    @Published var skipToDate: Bool = true
    @Published var showGuestCountView: Bool = false
    @Published var showChildrenAgeView: Bool = false
    @Published var withPet: Bool = false
    @Published var guestCount: Int = 0
    @Published var childrenCount: Int = 0
    @Published var childrenAges: [Int?] = []
    @Published var sheetFraction: CGFloat = 0.4
    
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
    
    let dataManager = CheckInDataManager()
    @Published var checkInData: CheckInData? = nil
    @Published var showLoadingIndicator: Bool = false
    
    init(router: AnyRouter, profileData: ProfileData? = nil) {
        self.router = router
        self.profileData = profileData
        addSubscribers()
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
        
        $profileData
            .sink { [weak self] data in
                guard let self else { return }
                if let address = profileData?.businessProfileRef?.address {
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
            .store(in: &cancellables)
        
        $guestCount
            .combineLatest($childrenCount, $withPet)
            .sink { [weak self] (guestCount, childrenCount, withPet) in
                guard let self else { return }
                guard guestCount > 0 else {
                    guestFieldText = ""
                    return
                }
                var string = ""
                
                string.append("\(guestCount) Adult")
                
                if childrenCount > 0 {
                    if childrenCount == 1 {
                        string.append(", \(childrenCount) Child")
                    } else {
                        string.append(", \(childrenCount) Children")
                    }
                }
                
                if withPet {
                    string.append(" with pet")
                }
                
                guestFieldText = string
            }
            .store(in: &cancellables)
        
        $childrenCount
            .sink { [weak self] count in
                guard let self else { return }
                
                if count <= 3 {
                    sheetFraction = 0.5
                } else if count >= 4 && count <= 7 {
                    sheetFraction = 0.7
                } else {
                    sheetFraction = 0.9
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func updateAgeArray() {
        let count: Int = childrenCount > childrenAges.count ? childrenCount - childrenAges.count : childrenAges.count - childrenCount
        
        if childrenCount > childrenAges.count {
            for _ in 0..<count {
                childrenAges.append(nil)
            }
        } else if childrenCount < childrenAges.count {
            for _ in 0..<count {
                childrenAges.removeLast()
            }
        }
    }
    
    
    func showAgeViewSheet() {
        showChildrenAgeView = true
    }
    
    
    func showRoomListView(checkInData: CheckInData) {
        if let profileData,
           let selectedFromDate,
           let selectedToDate {
            
            let bookingDetail = BookingDetail(fromDate: selectedFromDate, toDate: selectedToDate, fromDateString: fromDateString, toDateString: toDateString, toShowGuestString: guestFieldText, toShowAddressString: toShowAddressString, guestCount: guestCount, withPet: withPet, childrenCount: childrenCount, ageArray: childrenAges)
            
            router.showScreen(.push) { router in
                RoomListView(viewModel: RoomListViewModel(router: router, profileData: profileData, bookingDetail: bookingDetail, checkInData: checkInData))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
}

// MARK: - Helper Methods
extension BookingInfoViewModel {
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
}


// MARK: - Netwoking
extension BookingInfoViewModel {
    
    func checkIn() {
        
        guard let selectedFromDate,
              let selectedToDate,
              guestCount > 0 else { return }
        
        let fromString = formatToSendFormat(date: selectedFromDate)
        let toString = formatToSendFormat(date: selectedToDate)
        var ageArray: [String] = []
        
        var parameters: [String: Any] = [
            "businessProfileID": profileData?.businessProfileID ?? "",
            "checkIn": fromString,
            "checkOut": toString,
            "adults": guestCount,
            "isTravellingWithPet": withPet
        ]
        
        if childrenCount > 0 {
            parameters.updateValue("\(childrenCount)", forKey: "children")
            
            for age in childrenAges {
                if let age {
                    ageArray.append("\(age)")
                }
            }
            
            parameters.updateValue(ageArray, forKey: "childrenAge")
        }
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.checkIn(paramters: parameters)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            checkInData = data
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                                guard let self else { return }
                                showRoomListView(checkInData: data)
                            }
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
}
