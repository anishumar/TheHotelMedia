//
//  BookingCheckoutView.swift
//  TheHotelMedia
//
//  Created by MAC on 19/02/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Lottie

struct BookingCheckoutView: View {
    
    @StateObject var viewModel: BookingCheckoutViewModel
    var onPresseedChangeRoom: (() -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @AppStorage("name") var name: String = ""
    @AppStorage("email") var email: String = ""
    @AppStorage("phoneNumber") var phoneNumber: String = ""
    @AppStorage("dialCode") var dialCode: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomHeaderView(title: "Booking Confirmation".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    businessHeaderView
                    guestDetailSection
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                keyboardButton
                            }
                        }
                        .zIndex(1.0)
                    roomDetailSection
                    promoSection
                    billDetailSection
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 60)
                }
            }
        }
        .padding(.horizontal, 12)
        .overlay(alignment: .bottom, content: {
            Button {
                endEditing()
                
                guard viewModel.checkoutData != nil else {
                    viewModel.getCheckoutData() 
                    return
                }
                
                if let message = viewModel.checkGuestData(array: viewModel.guestArray) {
                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                } else {
                    startRazorpayPayment(amount: viewModel.amount, orderID: viewModel.orderID ?? "", email: viewModel.checkoutData?.user?.email ?? "", phoneNumber: "\(viewModel.checkoutData?.user?.phoneNumber ?? "")", currency: viewModel.currency)
                }
            } label: {
                HStack {
                    Image("Cash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    
                    Text("Pay now".localized(localizationManager.language))
                        .withComicFont(14, color: .white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        Capsule()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        Capsule()
                            .stroke(lineWidth: 1)
                            .fill(.hmIndigo.opacity(0.5))
                    }
                )
            }
            .padding(.bottom, 20)
//            .overlay {
//                if viewModel.allowPayment {
//                    RazorpayView(
//                        name: .constant("The Hotel Media"),
//                        app_name: .constant("The Hotel Media"),
//                        description: .constant("Room Booking"),
//                        image: .constant("https://s3.amazonaws.com/rzp-mobile/images/rzp.jpg"),
//                        themeColor: .constant("#082C50"),
//                        currency: $viewModel.currency,
//                        order_id: $viewModel.razorID,
//                        amount: $viewModel.amount,
//                        phoneNumber: $viewModel.phoneNumber,
//                        email: .constant("-------")) { paymentSuccessModel in
//                            
//                            print(paymentSuccessModel.paymentID, paymentSuccessModel.signature )
//                            viewModel.confirmBooking(paymentID: paymentSuccessModel.paymentID, signature: paymentSuccessModel.signature)
//                            
//                        } onPaymentError: { error in
//                            
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                }
//            } // RazorpayView
            

        })
        .overlay(content: {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        })
        .overlay(content: {
            ZStack {
                if viewModel.isBookingSuccessful {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.isBookingSuccessful = false
                                viewModel.dismissAllScreens()
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text(viewModel.successMessage)
                            .withComicFont(12, color: .white)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 8)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        })
        .onAppear {
            if viewModel.guestArray.isEmpty, !phoneNumber.isEmpty {
                viewModel.guestArray.append(PersonDetailModel(title: "Mr", name: name, email: email, phoneNumber: phoneNumber, dialCode: dialCode, isSelf: true))
                viewModel.getCheckoutData()
            } else {
                viewModel.allowEditing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeRoomNotification)) { notification in
            if let userInfo = notification.userInfo, let changedRoomID = userInfo["roomID"] as? String, let roomCount = userInfo["roomCount"] as? Int, let price = userInfo["price"] as? Double {
                viewModel.selectedRoomID = changedRoomID
                viewModel.roomCount = roomCount
                viewModel.roomPricePerNight = price
                viewModel.getCheckoutData()
            }
        }
//        .onReceive(razorpayManager.$onPaymentSuccess) { (value) in
//            if let value {
//                let response = value.1
//                if let paymentId = response?["razorpay_payment_id"] as? String,
//                   let rezorSignature = response?["razorpay_signature"] as? String {
//                    print(rezorSignature, paymentId )
//                    viewModel.confirmBooking(paymentID: paymentId, signature: rezorSignature)
//                }
//            }
//        }
        .onReceive(NotificationCenter.default.publisher(for: .razorpayPaymentSuccess)) { notification in
            if let paymentId = notification.userInfo?["payment_id"] as? String,
               let response = notification.userInfo?["response"] as? [AnyHashable: Any] {
                print("Payment succeeded: \(paymentId)")
                if let paymentId = response["razorpay_payment_id"] as? String,
                   let rezorSignature = response["razorpay_signature"] as? String {
                    print(rezorSignature, paymentId )
                    viewModel.confirmBooking(paymentID: paymentId, signature: rezorSignature)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .razorpayPaymentError)) { notification in
            if let code = notification.userInfo?["code"] as? Int32,
               let description = notification.userInfo?["description"] as? String {
                print("Payment failed with code \(code): \(description)")
                if code != 0 {
                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: description)
                }
            }
        }
    }
}


// MARK: - Helper Functions
extension BookingCheckoutView {
    func getAmountString(double: Double, format: String = "%.0f") -> String {
        String(format: format, double)
    }
    
    
    func startRazorpayPayment(amount: String, orderID: String, email: String, phoneNumber: String, currency: String) {
        viewModel.razorpayManager.presentRazorpay(
            amount: amount,         // ₹10 in paise
            orderId: orderID,
            email: email,
            phoneNumber: phoneNumber,
            currency: currency,
            name: "The Hotel Media",
            description: "Room Booking",
            image: "https://s3.amazonaws.com/rzp-mobile/images/rzp.jpg"
        )
    }
}


// MARK: - Components
extension BookingCheckoutView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.profileData.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.profileData.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.profileData.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.profileData.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    
                    if let rating = viewModel.profileData.businessProfileRef?.rating {
                        if rating > 0 {
                            HStack(spacing: 2) {
                                Text("-")
                                    .foregroundColor(.white.opacity(0.8))
                                Image("RatingStar")
                                    .renderingMode(.template)
                                    .foregroundColor(rating.getStarColor())
                                    .frame(height: 12)
                                
                                Text("\(String(format: "%.1f", rating))")
                            }
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(rating.getStarColor())
                        }
                    }
                }
                
                
                Text(viewModel.bookingDetail.toShowAddressString)
                    .withComicFont(11, color: .white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.5))
            }
        )
    }
    
    
    private func headerTitleView(icon: String, title: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            Text(title)
                .withComicFont(16, color: themeManager.currentTheme.white_darkGray)
        }
    }
    
    
    private func detailLineView(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
            Spacer()
            Text(value)
        }
        .withComicFont(13, color: themeManager.currentTheme.white_darkGray)
    }
    
    
    private func billDetailLine(title: String, subtitle: String? = nil, value: String, valueColor: Color? = nil) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .withComicFont(13, color: themeManager.currentTheme.white_darkGray)
                if let subtitle {
                    Text(subtitle)
                        .withComicFont(10, color: themeManager.currentTheme.white06_darkGray06)
                }
            }
            
            Spacer()
            Text(value)
                .withComicFont(13, color: valueColor == nil ? themeManager.currentTheme.white_darkGray : valueColor ?? .white)
        }
    }
    
    
    private var guestDetailSection: some View {
        VStack(spacing: 10) {
            // header
            HStack {
                headerTitleView(icon: "Guest-Detail", title: "Guest Details".localized(localizationManager.language))
                Spacer()
                if !viewModel.allowEditing {
                    Button {
                        viewModel.allowEditing = true
                    } label: {
                        Text("Change".localized(localizationManager.language))
                            .withComicFont(14, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
                    }
                } else {
                    Button {
                        viewModel.addNewGuest()
                    } label: {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image("Plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                            }
                    }

                }
            }
            
            if viewModel.allowEditing {
                ForEach($viewModel.guestArray) { guest in
                    if let index = viewModel.guestArray.firstIndex(where: {$0.id == guest.id}) {
                        GuestDetailCard(personModel: guest, showOption: index == 0 ? true : false) {
                            viewModel.guestArray.remove(at: index)
                        }
                        .zIndex(Double(viewModel.guestArray.count - index))
                        .padding(2)
                    }
                }
                
            } else if !viewModel.guestArray.isEmpty {
                
                let selfModel = viewModel.guestArray[0]
                VStack(spacing: 12) {
                    detailLineView(title: "Name".localized(localizationManager.language), value: selfModel.name)
                    detailLineView(title: "Email".localized(localizationManager.language), value: selfModel.email)
                    detailLineView(title: "Phone Number".localized(localizationManager.language), value: "\(selfModel.dialCode)\(selfModel.phoneNumber)")
                }
                .padding(10)
                .background(roundedBackground)
                .padding(2)
            }
            
        }
    }
    
    
    private var billDetailSection: some View {
        VStack {
            headerTitleView(icon: "BillIcon2", title: "bill_details".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                let title = viewModel.checkoutData?.room?.title ?? ""
                let nights = viewModel.checkoutData?.bookedRoom?.nights ?? 1
                let subtotal = viewModel.checkoutData?.payment?.subtotal ?? 0
                let convinceCharges = viewModel.checkoutData?.payment?.convinceCharges ?? 0
                let gstRate = viewModel.checkoutData?.payment?.gstRate ?? 0
                let gst = viewModel.checkoutData?.payment?.gst ?? 0
                let total = viewModel.checkoutData?.payment?.total ?? 0
                
                billDetailLine(title: title, subtitle: "\(nights) Night", value: "₹\(subtotal)")
                
                if let promocode = viewModel.checkoutData?.payment?.promocode, let discount = viewModel.checkoutData?.payment?.discount {
                    billDetailLine(title: "Promocode", subtitle: promocode.name ?? "", value: "-₹" + getAmountString(double: discount, format: "%.2f"), valueColor: .hmRed2)
                }
                
                billDetailLine(title: "Convenience charges".localized(localizationManager.language), value: "₹" + getAmountString(double: convinceCharges, format: "%.2f"))
                billDetailLine(title: "GST(\(getAmountString(double: gstRate) )%)", value: "₹" + getAmountString(double: gst, format: "%.2f"))
                
                DottedLine()
                    .stroke(style: .init(lineWidth: 1, dash: [3]))
                    .foregroundStyle(themeManager.currentTheme.white03_darkGray03)
                    .frame(height: 1)
                
                billDetailLine(title: "Total".localized(localizationManager.language), value: "₹" + getAmountString(double: total, format: "%.2f"))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private var roomDetailSection: some View {
        VStack(spacing: 10) {
            HStack {
                headerTitleView(icon: "Room-Type", title: "Room type".localized(localizationManager.language))
                Spacer()
                Button {
                    viewModel.showRoomListScreen()
//                    viewModel.dismissScreen()
//                    onPresseedChangeRoom?()
                } label: {
                    Text("Change Room".localized(localizationManager.language))
                        .withComicFont(14, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
                }
            }
            
            HStack {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image("Bed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                
                Text(viewModel.checkoutData?.room?.title ?? "")
                    .withComicFont(16, color: themeManager.currentTheme.white_darkGray)
                Spacer()
                Text("\(viewModel.checkoutData?.bookedRoom?.quantity ?? 1) Room")
                    .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
            
            HStack {
                checkInTimeView(title: "Check-in".localized(localizationManager.language), icon: "Open-Door", value: DateManager.formatDateTodMMM(from: viewModel.bookingDetail.fromDate))
                Spacer()
                checkInTimeView(title: "Check-out".localized(localizationManager.language), icon: "Open-Door", value: DateManager.formatDateTodMMM(from: viewModel.bookingDetail.toDate))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineWidth: 1)
                .fill(.hmDarkerGray)
        }
    }
    
    
    private func checkInTimeView(title: String, icon: String, value: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(4)
                .background(
                    Circle()
                        .fill(.mediumBlue)
                )
                .padding(5)
                .background(
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.darkGray06_white)
                        if themeManager.darkThemeActive {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.hmDarkerGray)
                            
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
                
                Text(value)
                    .withComicFont(14, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
            }
        }
    }
    
    
    private var promoSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("PromoCode2")
                Text("promo_code".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.white_darkGray)
            }
            
            HStack {
                TextField(
                    "",
                    text: $viewModel.promoFieldText,
                    prompt: Text("promocode".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white_darkGray)
                )
                .textInputAutocapitalization(.characters)
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white_darkGray)
                .padding(.horizontal)
                .overlay {
                    if viewModel.checkoutData?.payment?.promocode != nil {
                        Rectangle()
                            .fill(.black.opacity(0.001))
                    }
                }
                
                Text(viewModel.checkoutData?.payment?.promocode != nil ? "remove".localized(localizationManager.language).capitalized : "apply".localized(localizationManager.language).capitalized)
                    .withComicFont(16, color: viewModel.checkoutData?.payment?.promocode != nil ? .hmRed2 : themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .fontWeight(.bold)
                    .onTapGesture {
                        endEditing()
                        guard !viewModel.promoFieldText.isEmpty else { return }
                        
                        if viewModel.checkoutData?.payment?.promocode == nil {
                            viewModel.getCheckoutData(promocode: viewModel.promoFieldText)
                        } else {
                            viewModel.getCheckoutData()
                        }
                    }
                    .padding(.trailing)
                    
            }
            .padding(12)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private var keyboardButton: some View {
        HStack {
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                    
            })
        }
    }
    
    
}
