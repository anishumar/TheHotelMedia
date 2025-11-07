//
//  BookingSummaryView.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct BookingSummaryView: View {
    
    @StateObject var viewModel: BookingSummaryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack {
            CustomHeaderView(title: "Booking Summary".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .background(themeManager.currentTheme.backgroundColor)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if viewModel.bookingCancelled {
                        HStack {
                            Image("Cancel")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            
                            Text("Booking Cancelled!".localized(localizationManager.language))
                                .withComicFont(16, color: .white)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.hmRed)
                        )
                    }
                    businessHeaderView
                    bookingDetailSection
                    roomDetailSection
                    billDetailSection
                    Spacer(minLength: 70)
                }
            }
            
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            if let freeCancel = viewModel.bookingSummary?.freeCancel, !viewModel.bookingCancelled, viewModel.lastScreen != "notification" {
                if freeCancel {
                    Button {
                        viewModel.showCancelBookingModal()
                    } label: {
                        HStack {
                            Image("Cancel")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            
                            Text("Cancel Booking".localized(localizationManager.language))
                                .withComicFont(15, color: .white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                Capsule()
                                    .fill(themeManager.currentTheme.hmred2_05_hmred2_08)
                                Capsule()
                                    .stroke(lineWidth: 1)
                                    .fill(.hmRed2)
                            }
                        )
                    }
                    .padding(.bottom, 20)
                } else {
                    Button {
                        viewModel.showDownloadInvoiceModal()
                    } label: {
                        HStack {
                            Image("Arrow-Down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            
                            Text("Download Invoice".localized(localizationManager.language))
                                .withComicFont(15, color: .white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                                Capsule()
                                    .stroke(lineWidth: 1)
                                    .fill(.hmIndigo)
                            }
                        )
                    }
                    .padding(.bottom, 20)
                }
            }
            
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Helper Functions
extension BookingSummaryView {
    func getAmountString(double: Double, format: String = "%.0f") -> String {
        String(format: format, double)
    }
}


// MARK: - Components
extension BookingSummaryView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.bookingSummary?.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.bookingSummary?.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.bookingSummary?.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.bookingSummary?.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    let rating: Double? = viewModel.bookingSummary?.businessProfileRef?.rating
                    if let rating = rating {
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
                
                if let businessProfileRef = viewModel.bookingSummary?.businessProfileRef,
                   let address = businessProfileRef.address,
                   let street = address.street,
                   let city = address.city,
                   let state = address.state,
                   let zipCode = address.zipCode,
                   let country = address.country {
                    
                    Text("\(street), \(city), \(state), \(zipCode), \(country)")
                        .withComicFont(11, color: .white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
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
    
    
    private func detailLineView(title: String, value: String, addColon: Bool = true) -> some View {
        HStack {
            Text(addColon ? title + ":" : title)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
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
    
    
    private var roundedBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineWidth: 1)
                .fill(.hmDarkerGray)
        }
    }
    
    
    private var roomDetailSection: some View {
        VStack(spacing: 10) {
            headerTitleView(icon: "Room-Type", title: "Room type".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
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
                
                Text(viewModel.bookingSummary?.roomsRef?.title ?? "")
                    .withComicFont(16, color: themeManager.currentTheme.white_darkGray)
                Spacer()
                Text("\(viewModel.bookingSummary?.bookedRoom?.quantity ?? 1) Room")
                    .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
            
            HStack {
                checkInTimeView(title: "Check-in".localized(localizationManager.language), icon: "Open-Door", value: (DateManager.convertISOToDateAndMonth(from: viewModel.bookingSummary?.checkIn ?? "") ?? ""))
                Spacer()
                checkInTimeView(title: "Check-out".localized(localizationManager.language), icon: "Open-Door", value: (DateManager.convertISOToDateAndMonth(from: viewModel.bookingSummary?.checkOut ?? "") ?? ""))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
            
            if !viewModel.bookingCancelled, let freeCancel = viewModel.bookingSummary?.freeCancel, viewModel.lastScreen != "notification", freeCancel {
                HStack {
                    Image("Paper-Broken")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    
                    Text("\("Free Cancellation till".localized(localizationManager.language)) \((DateManager.formatISODateToBookedOn(from: viewModel.bookingSummary?.freeCancelBy ?? "") ?? ""))")
                        .withComicFont(11, color: .white)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6.5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.hmGreen3)
                )
            }
            
        }
    }
    
    
    private var bookingDetailSection: some View {
        VStack (spacing: 10){
            headerTitleView(icon: "Guest-Detail", title: "Booking Details".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 12) {
                if let guests = viewModel.bookingSummary?.guestDetails {
                    ForEach(guests) { guest in
                        if let index = guests.firstIndex(where: {$0.id == guest.id}) {
                            let remainder = index + 1 % 10
                            if remainder == 1 {
                                detailLineView(title: "Guest \(index + 1)st".localized(localizationManager.language), value: guest.fullName ?? "", addColon: false)
                                
                            } else if remainder == 2 {
                                detailLineView(title: "Guest \(index + 1)nd".localized(localizationManager.language), value: guest.fullName ?? "", addColon: false)
                                
                            } else if remainder == 3 {
                                detailLineView(title: "Guest \(index + 1)rd".localized(localizationManager.language), value: guest.fullName ?? "", addColon: false)
                                
                            } else {
                                detailLineView(title: "Guest \(index + 1)th".localized(localizationManager.language), value: guest.fullName ?? "", addColon: false)
                            }
                        }
                    }
                }
                
                if let user = viewModel.bookingSummary?.usersRef,
                   let email = user.email,
                   let dialCode = user.dialCode,
                   let phoneNumber = user.phoneNumber {
                    detailLineView(title: "Email".localized(localizationManager.language), value: email)
                    detailLineView(title: "Phone Number".localized(localizationManager.language), value: "\(dialCode) \(phoneNumber)")
                }
               
                detailLineView(title: "Booking ID".localized(localizationManager.language), value: viewModel.bookingSummary?.bookingID ?? "")
                detailLineView(title: "Payment Method".localized(localizationManager.language), value: viewModel.bookingSummary?.paymentDetail?.paymentMethod ?? "")
                detailLineView(title: "Date & time".localized(localizationManager.language), value: (DateManager.formatISODateToBookedOn(from: viewModel.bookingSummary?.createdAt ?? "") ?? ""))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private var billDetailSection: some View {
        VStack {
            headerTitleView(icon: "BillIcon2", title: "bill_details".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                let title = viewModel.bookingSummary?.roomsRef?.title ?? ""
                let nights = viewModel.bookingSummary?.bookedRoom?.nights ?? 1
                let subtotal: Double = viewModel.bookingSummary?.subTotal ?? 0
                let convinceCharges: Double = viewModel.bookingSummary?.convinceCharge ?? 0
                let gstRate: Double = viewModel.bookingSummary?.gstRate ?? 18
                let gst: Double = viewModel.bookingSummary?.tax ?? 0
                let total: Double = viewModel.bookingSummary?.grandTotal ?? 0
                
                billDetailLine(title: title, subtitle: nights <= 1 ? "\(nights) \("Night".localized(localizationManager.language))" : "\(nights) \("Nights".localized(localizationManager.language))", value: "₹" + getAmountString(double: subtotal))
                
                if let discount = viewModel.bookingSummary?.discount, discount != 0 {
                    billDetailLine(title: "promocode".localized(localizationManager.language), subtitle: viewModel.bookingSummary?.promoCode ?? "", value: "-₹" + getAmountString(double: discount), valueColor: .hmRed2)
                }
                
                billDetailLine(title: "Convenience charges".localized(localizationManager.language), value: "₹" + getAmountString(double: convinceCharges))
                billDetailLine(title: "GST(\(getAmountString(double: gstRate) )%)", value: "₹" + getAmountString(double: gst))
                
                DottedLine()
                    .stroke(style: .init(lineWidth: 1, dash: [3]))
                    .foregroundStyle(themeManager.currentTheme.white03_darkGray03)
                    .frame(height: 1)
                
                billDetailLine(title: "Total".localized(localizationManager.language), value: "₹" + getAmountString(double: total))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
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
    
}

