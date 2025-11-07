//
//  BookingCheckoutViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 19/02/25.
//

import SwiftUI
import Combine
import SwiftfulRouting


class BookingCheckoutViewModel: ObservableObject {
    
    let router: AnyRouter
    let bookingDetail: BookingDetail
    let profileData: ProfileData
    let checkInData: CheckInData
    var roomPricePerNight: Double?
    var selectedRoomID = ""
    var roomCount = 1
    var cancellables = Set<AnyCancellable>()
    @Published var allowEditing: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var allowPayment: Bool = false
    @Published var showRazorpay: Bool = false
    @Published var promoFieldText: String = ""
    @Published var currency: String = ""
    @Published var razorID: String = ""
    @Published var amount: String = ""
    @Published var phoneNumber: String = ""
    @Published var orderID: String? = nil
    @Published var guestArray: [PersonDetailModel] = []
    @Published var checkoutData: BookingCheckoutData? = nil
    @Published var onPaymentSuccess: ((String, [AnyHashable: Any]?) -> Void)?
    @Published var onPaymentError: ((Int32, String, [AnyHashable: Any]?) -> Void)?
    @Published var success: AnyCancellable?
    @Published var isBookingSuccessful: Bool = false
    @Published var successMessage: String = ""
    let dataManager = BookingCheckoutDataManager()
    let razorpayManager = RazorpayWindowManager()
    
    init(router: AnyRouter, bookingDetail: BookingDetail, profileData: ProfileData, checkInData: CheckInData, selectedRoomID: String, roomCount: Int, roomPricePerNight: Double? = nil) {
        self.router = router
        self.bookingDetail = bookingDetail
        self.profileData = profileData
        self.checkInData = checkInData
        self.selectedRoomID = selectedRoomID
        self.roomCount = roomCount
        self.roomPricePerNight = roomPricePerNight
        addSubscribers()
//        addSuccessResponseSubscriber()
    }
    
    func addSubscribers() {
        $guestArray
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink { [weak self] array in
                guard let self else { return }
                if let _ = checkGuestData(array: array) {
                    allowPayment = false
                } else {
                    allowPayment = true
                }
            }
            .store(in: &cancellables)
        
        $checkoutData
            .sink { [weak self] data in
                guard let self else { return }
                
                guard let data else { return }
                
                if let razorpay = data.razorPayOrder {
                    if let currency = razorpay.currency {
                        self.currency = currency
                    }
                    
                    if let amount = razorpay.amount {
                        self.amount = "\(amount)"
                    }
                    
                    if let orderID = razorpay.id {
                        self.orderID = orderID
                    }
                    
                    if let phoneNumber = data.user?.phoneNumber, let dialCode = data.user?.dialCode {
                        self.phoneNumber = "\(dialCode)\(phoneNumber)"
                    }
                }
                
                if data.payment?.promocode == nil {
                    promoFieldText = ""
                }
            }
            .store(in: &cancellables)
    }
    
    
//    func addSuccessResponseSubscriber() {
//        success = razorpayManager.$onPaymentSuccess
//            .sink(receiveValue: { [weak self] value in
//                guard let self else { return }
//                if let value {
//                    let response = value.1
//                    if let paymentId = response?["razorpay_payment_id"] as? String,
//                       let rezorSignature = response?["razorpay_signature"] as? String {
//                        print(rezorSignature, paymentId )
//                        confirmBooking(paymentID: paymentId, signature: rezorSignature)
//                        success?.cancel()
//                        success = nil
//                    }
//                }
//            })
//    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func checkGuestData(array: [PersonDetailModel]) -> String? {
        var messageString: String? = nil
        for guest in array {
            messageString = checkGuestModel(model: guest)
            if let messageString {
                return messageString
            }
        }
        
        return messageString
    }
    
    
    func checkGuestModel(model: PersonDetailModel) -> String? {
        guard !model.name.isEmpty else {
            return "Please enter a valid name."
        }
        
        guard !model.title.isEmpty else {
            return "Please select a title."
        }
        
        guard isValidEmail(model.email) else {
            return "Please enter a valid email address."
        }
        
        guard !model.dialCode.isEmpty, model.phoneNumber.count >= 10 else {
            return "Please enter a valid phone number."
        }
        
        return nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    func showRoomListScreen() {
        router.showScreen(.fullScreenCover) { router in
            RoomListView(viewModel: RoomListViewModel(router: router, profileData: self.profileData, bookingDetail: self.bookingDetail, checkInData: self.checkInData, isPresentedAsSheet: true))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func addNewGuest() {
        var guest = PersonDetailModel(title: "Mr", name: "", email: "", phoneNumber: "", dialCode: "+91")
        guestArray.append(guest)
    }
    
    
    func dismissAllScreens() {
        router.dismissScreenStack()
    }
    
}

// MARK: - Networking
extension BookingCheckoutViewModel {
    
    func getCheckoutData(promocode: String? = nil) {
        
        guard let bookingID = checkInData.booking?.bookingID else { return }
        let bookedFor = guestArray[0].isSelf ? "myself" : "someone-else"
        
      
        
        var parameters: [String: Any] = [
            "bookingID": bookingID,
            "roomID": selectedRoomID,
            "bookedFor": bookedFor,
            "quantity": roomCount,
            "price": roomPricePerNight ?? 0
//            "guestDetails": jsonStringArray
        ]
        
        if let promocode, !promocode.isEmpty {
            parameters.updateValue(promocode, forKey: "promoCode")
        }
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.getCheckoutData(parameters: parameters)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            checkoutData = data
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Internal server error!")
                }
            }
        }
    }
    
    
    func confirmBooking(paymentID: String, signature: String) {
        guard let bookingID = checkInData.booking?.bookingID else { return }
        let bookedFor = guestArray[0].isSelf ? "myself" : "someone-else"
        
        var jsonStringArray: [String] = []
        
        for person in guestArray {
            let sendModel = GuestModel(title: person.title, fullName: person.name, email: person.email, mobileNumber: "\(person.dialCode)\(person.phoneNumber)")
            
            if let jsonData = try? JSONEncoder().encode(sendModel),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                jsonStringArray.append(jsonString)
            }
        }
        
        let parameters: [String: Any] = [
            "bookingID": bookingID,
            "bookedFor": bookedFor,
            "guestDetails": jsonStringArray,
            "paymentID": paymentID,
            "signature": signature,
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.confirmBooking(parameters: parameters)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        successMessage = result.message
                        isBookingSuccessful = true
                        
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//                            guard let self else { return }
//                            self.dismissAllScreens()
//                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Internal server error!")
                }
            }
        }
    }
}
