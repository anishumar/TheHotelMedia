//
//  RoomDetailViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI
import Combine
import SwiftfulRouting
import CountryPickerView
import FirebaseAuth


class RoomDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let profileData: ProfileData
    let bookingDetail: BookingDetail
    var checkInData: CheckInData
    let roomID: String
    var isPresentedAsSheet: Bool
    var isExpanded: Bool = false
    var minRoom: Int = 1
    var maxRoom: Int = 5
    @Published var descriptionText: String = ""
    @Published var attributedDescriptionText: AttributedString = ""
    @Published var currentRoomCount: Int = 1
    @Published var perRoomPrice: Double = 0
    @Published var roomData: RoomData? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var showAllAmenities: Bool = false
    @Published var phoneNoVerified: Bool = false
    @Published var selectedCountry: Country? = nil
    @Published var toVerifyPhoneNumber: String = ""
    @Published var toVerifyDialCode: String = "+91"
    @Published var otpFieldText: String = ""
    @Published var showContactModal: Bool = false
    @Published var showVerifyModal: Bool = false
    @Published var showMediaPreview: Bool = false
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var countDownEnded: Bool = true
    @Published var counter: Int = 60
    
    let dataManager = RoomDataManager()
    let verifyDataManager = MobileVerificationDataManager()
    var cancellables = Set<AnyCancellable>()
    private var cancellable: Cancellable?
    
    @AppStorage("phoneNumber") var phoneNumber: String = ""
    @AppStorage("dialCode") var dialCode: String = ""
    
    
    @AppStorage("verificationID") var currentVerificationID: String = ""
    
    init(router: AnyRouter, profileData: ProfileData, bookingDetail: BookingDetail, checkInData: CheckInData, roomID: String, isPresentedAsSheet: Bool = false, roomPricePerNight: Double) {
        self.router = router
        self.profileData = profileData
        self.bookingDetail = bookingDetail
        self.checkInData = checkInData
        self.roomID = roomID
        self.isPresentedAsSheet = isPresentedAsSheet
        self.minRoom = checkInData.roomsRequired ?? 1
        self.currentRoomCount = checkInData.roomsRequired ?? 1
        self.toVerifyPhoneNumber = checkInData.user?.phoneNumber ?? ""
        self.perRoomPrice = roomPricePerNight
        if let dialCode = checkInData.user?.dialCode, !dialCode.isEmpty {
            self.toVerifyDialCode = dialCode
        }
        addSubscribers()
        getRoomData(id: roomID)
        
        self.selectedCountry = CountryHelper.shared.getCountry(dialCode: toVerifyDialCode)
    }
    
    
    func addSubscribers() {
        $roomData
            .sink { [weak self] data in
                guard let self else { return }
                descriptionText = data?.description ?? ""
//                perRoomPrice = data?.pricePerNight ?? 0
            }
            .store(in: &cancellables)
        
        $descriptionText
            .sink { [weak self] text in
                guard let self else { return }
                if !text.isEmpty {
                    getAttributedDescription(id: "room-detail", descriptionText: text)
                }
            }
            .store(in: &cancellables)
        
        $selectedCountry
            .sink { [weak self] country in
                guard let self else { return }
                if let country {
                    toVerifyDialCode = country.phoneCode
                }
            }
            .store(in: &cancellables)
    }
    
    
    func startTimer() {
        counter = 60
        
        countDownEnded = false
        
        let countDownTimer = Timer.publish(every: 1.0, on: .main, in: .default).autoconnect()
        
        cancellable = countDownTimer
            .sink{ [weak self] _ in
                guard let self else { return }
                
                guard counter > 0 else {
                    cancelTimer()
                    return
                }
                
                self.counter -= 1
            }
    }
    
    
    func cancelTimer() {
        countDownEnded = true
        cancellable?.cancel()
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func getAttributedDescription(id: String, descriptionText: String) {
        let isContentLong = descriptionText.count > 160
        let truncatedContent = isContentLong ? String(descriptionText.prefix(160)) : descriptionText
        var attributedString = AttributedString(isExpanded ? descriptionText : truncatedContent)
        
        // Regular expression for URLs
        let urlRegex = try! NSRegularExpression(pattern: "(https?://[a-zA-Z0-9._%+-]+\\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9._%+-]*)*(?:\\?[a-zA-Z0-9&=_%+-]*)?)", options: [])
        let matches = urlRegex.matches(in: descriptionText, options: [], range: NSRange(descriptionText.startIndex..., in: descriptionText))
        
        // Add tappable links for URLs
        for match in matches {
            guard let rangeInString = Range(match.range, in: descriptionText),
                  let rangeInAttributedString = Range(match.range, in: attributedString) else {
                continue
            }
            let urlText = String(descriptionText[rangeInString])
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
        
        attributedDescriptionText = attributedString
    }
    
    
    private func appendTappableText(_ attributedString: inout AttributedString, text: String, link: String) {
        var tappableText = AttributedString(text)
        tappableText.link = URL(string: link)
        tappableText.foregroundColor = .hmIndigo
        tappableText.font = .custom(Constants.comicFont, size: 13.2)
        attributedString.append(tappableText)
    }
    
    
    func showCheckoutScreen() {
        if isPresentedAsSheet {
            router.dismissEnvironment()
            roomChanged()
        } else {
            router.showScreen(.push) { router in
                BookingCheckoutView(viewModel: BookingCheckoutViewModel(router: router, bookingDetail: self.bookingDetail, profileData: self.profileData, checkInData: self.checkInData, selectedRoomID: self.roomID, roomCount: self.currentRoomCount, roomPricePerNight: self.perRoomPrice), onPresseedChangeRoom: {
                    self.router.dismissScreen()
                })
                    .environmentObject(ThemeManager.shared)
                    .transaction({ transaction in
                        transaction.disablesAnimations = true
                    })
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    private func roomChanged() {
        NotificationCenter.default.post(name: .changeRoomNotification, object: nil, userInfo: ["roomID": roomID, "roomCount": currentRoomCount, "price": perRoomPrice])
    }
}

// MARK: - Notification Center

extension Notification.Name {
    static let changeRoomNotification = Notification.Name("changeRoomNotification")
}


// MARK: - Networking
extension RoomDetailViewModel {
    func getRoomData(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getRoomData(id: id)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            roomData = data
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
    
    
    func requestOtp(resend: Bool = false) {
        guard !toVerifyDialCode.isEmpty else { return }
        
        guard toVerifyPhoneNumber.count >= 10 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a valid phone number.")
            return
        }
        
        showLoadingIndicator = true
        
        let phoneNumber = toVerifyDialCode + toVerifyPhoneNumber
        print("📱 Requesting OTP for number: \(phoneNumber)")
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showLoadingIndicator = false
                
                if let error = error {
                    ErrorModalManager.showErrorModal(router: self.router, errorText: error.localizedDescription)
                    return
                }
                
                if let verificationID = verificationID {
                    self.currentVerificationID = verificationID
                    
                    if !resend {
                        withAnimation(.easeInOut) {
                            self.showContactModal = false
                            self.showVerifyModal = true
                        }
                    } else {
                        // Optional: Show "OTP Resent" toast/alert
                    }
                }
            }
        }
    }
    
    
    func verifyOtp() {
        guard otpFieldText.count >= 6 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter the full 6-digit OTP.")
            return
        }
        
        showLoadingIndicator = true
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: currentVerificationID,
            verificationCode: otpFieldText
        )
        
        let dialCode = toVerifyDialCode
        let phoneNumber = toVerifyPhoneNumber
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showLoadingIndicator = false
                
                if let error = error {
                    ErrorModalManager.showErrorModal(router: self.router, errorText: error.localizedDescription)
                    print(error.localizedDescription)
                    return
                }
                
                // User is signed in
                // Sign out immediately as we only needed verification
                try? Auth.auth().signOut()
                
                self.showVerifyModal = false
                self.phoneNumber = phoneNumber
                self.dialCode = dialCode
                self.checkInData.user?.mobileVerified = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showCheckoutScreen()
                }
            }
        }
    }
}
